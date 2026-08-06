# typed: strict
# frozen_string_literal: true

require 'graphql'
require 'logger'
require 'sorbet-runtime'

require 'fragment_client/typed_ledger_entry'

class FragmentClient
  # Namespace the derived payload classes are registered under, so a caller can
  # name one directly: `FragmentClient::Entries::AuthCaptureV1`.
  #
  # Deliberately empty. Every constant here is defined at load time from a
  # `.graphql` document, and anything else in this namespace could collide with
  # a Ledger Entry type. The machinery lives in {FragmentClient::TypedEntries}.
  module Entries; end

  # Derives strongly-typed `addLedgerEntries` payloads from the per-entry-type
  # `addLedgerEntry` operations the Fragment CLI generates for a Schema.
  #
  # `addLedgerEntries(entries: [AddLedgerEntryInput!]!)` commits a batch
  # atomically, and every entry's `parameters` field is an opaque `JSON` scalar.
  # GraphQL therefore cannot type the parameters of an individual entry in a
  # batch: one list means one input type, so callers are left passing untyped
  # hashes.
  #
  # A generated single-entry operation carries both missing facts -- the entry
  # type as a string literal, and each parameter bound to a typed variable:
  #
  #     mutation PostAuthCapture($ik: SafeString!, $ledgerIk: SafeString!,
  #                              $capture_amount: String!) {
  #       addLedgerEntry(ik: $ik, entry: {
  #         ledger: {ik: $ledgerIk}, type: "auth_capture",
  #         parameters: {capture_amount: $capture_amount}
  #       }) { __typename }
  #     }
  #
  # {.load} recovers that into an {EntrySpec} and defines one payload class per
  # `(type, typeVersion)` pair:
  #
  #     FragmentClient::TypedEntries.load('app/graphql/entries.graphql')
  #     entry = FragmentClient::Entries::AuthCaptureV1.new(
  #       ik: 'ik-1', ledger_ik: 'prod', capture_amount: '100'
  #     )
  #     client.add_ledger_entries(entries: [entry])
  #
  # Classes are built at load time rather than generated to disk, because that is
  # how Ruby libraries normally do this. Sorbet learns about them from the
  # Tapioca DSL compiler this gem ships (`bundle exec tapioca dsl`), the same way
  # it learns about ActiveRecord attributes.
  #
  # Implements the shared SDK specification `typed-batch-entries.md` from
  # `fragment-dev/graphql-queries`; see `docs/spec-conformance.md` for the
  # section-by-section mapping. Section references below are to that spec.
  module TypedEntries
    extend T::Sig

    # The only field an operation may select to qualify as a typed entry
    # operation (spec 2.1).
    ADD_LEDGER_ENTRY_FIELD = 'addLedgerEntry'

    # An entry with no `typeVersion` resolves to version 1 server-side -- never
    # to the latest version -- so an unpinned operation is normalised to 1 at
    # extraction. That keeps one rule for the identity, the class name and the
    # wire payload instead of letting them disagree (spec 2.5).
    DEFAULT_TYPE_VERSION = 1

    # Sentinel for "the caller did not set this field", distinct from `nil`.
    #
    # Spec 3.2 requires an unset field to be omitted rather than serialized as
    # `null`, because `null` is a value a caller may pass deliberately and the
    # two must stay distinguishable. Ruby's usual `nil` default cannot express
    # three states, so optional fields default to {UNSET} instead.
    class Unset
      extend T::Sig

      sig { returns(String) }
      def inspect
        'FragmentClient::TypedEntries::UNSET'
      end

      alias to_s inspect
    end

    UNSET = T.let(Unset.new.freeze, Unset)

    # One templated parameter of a typed Ledger Entry.
    class Parameter < T::Struct
      extend T::Sig

      # The parameter name as the Schema knows it. This is the JSON key sent
      # inside `parameters`, so it goes on the wire verbatim (spec 3.3).
      const :wire_name, String

      # The keyword argument and reader name on the payload class. Identical to
      # `wire_name` unless that name is already taken (see
      # {TypedEntries.local_name}).
      const :name, Symbol

      # The GraphQL type of the bound variable, rendered as written -- `String!`,
      # `[SafeString!]`. Carried so the Tapioca compiler can turn it into a
      # Sorbet type; unused at runtime.
      const :graphql_type, String

      # Whether the bound variable is non-null, i.e. the caller must supply it.
      const :required, T::Boolean

      sig { returns(T::Boolean) }
      def escaped?
        wire_name.to_sym != name
      end

      # `T::Struct` compares by identity, which would make every conflict check
      # and every snapshot comparison report a difference between two parameters
      # that are in fact the same.
      sig { params(other: T.untyped).returns(T::Boolean) }
      def ==(other)
        other.is_a?(Parameter) && serialize == other.serialize
      end
    end

    # Everything needed to define one payload class.
    class EntrySpec < T::Struct
      extend T::Sig

      const :entry_type, String

      # Always concrete: an unpinned operation is normalised to
      # {DEFAULT_TYPE_VERSION}, because that is what the API resolves it to.
      const :type_version, Integer

      # The operation this was derived from. Informational -- it names the class
      # only in the pathological collision case (spec 2.5).
      const :operation_name, String

      # In the order the parameters appear in the source `parameters: {...}`
      # literal. All four SDKs read the same document, so source order is the
      # only ordering they can agree on without coordinating (spec 2.4).
      const :parameters, T::Array[Parameter]

      # What a payload is keyed on (spec 2.2). Not the entry type alone: the same
      # type at two versions has different parameter sets, and collapsing them
      # would drop one and post the wrong version.
      sig { returns([String, Integer]) }
      def identity
        [entry_type, type_version]
      end

      # The payload class name, always carrying the version it resolves to.
      #
      # Depends only on this payload's own identity, never on which other
      # operations are in the input. Suffixing only when versions collide would
      # mean adding a second version later renames the first, breaking every
      # existing call site for a purely additive Schema change (spec 2.5, 2.6).
      sig { returns(String) }
      def class_name
        "#{TypedEntries.constant_name(entry_type)}V#{type_version}"
      end

      sig { params(other: EntrySpec).returns(T::Boolean) }
      def same_parameters?(other)
        parameters == other.parameters
      end
    end

    class Error < StandardError; end

    # Raised when a batch is built for an entry type that was never loaded.
    class UnknownEntryTypeError < Error; end

    class << self
      extend T::Sig

      # Derive payload classes from `.graphql` documents and define them under
      # `namespace`.
      #
      # Idempotent: loading the same document twice reuses the classes already
      # defined for each identity rather than redefining the constants. Needs no
      # credentials and makes no network calls, so it is safe to call from an
      # initializer -- which is what lets `tapioca dsl` see the classes.
      sig do
        params(paths: String, namespace: Module)
          .returns(T::Array[T.class_of(FragmentClient::TypedLedgerEntry)])
      end
      def load(*paths, namespace: Entries)
        paths.flat_map { |path| load_string(File.read(path), namespace: namespace, origin: path) }
      end

      # {load}, for a document already in memory.
      sig do
        params(source: String, namespace: Module, origin: T.nilable(String))
          .returns(T::Array[T.class_of(FragmentClient::TypedLedgerEntry)])
      end
      def load_string(source, namespace: Entries, origin: nil)
        define(extract(GraphQL.parse(source)), namespace: namespace, origin: origin)
      end

      # The payload class for an entry type, defaulting to the version an
      # unpinned entry resolves to.
      sig do
        params(entry_type: String, type_version: Integer)
          .returns(T.class_of(FragmentClient::TypedLedgerEntry))
      end
      def fetch(entry_type, type_version = DEFAULT_TYPE_VERSION)
        registry.fetch([entry_type, type_version]) do
          raise UnknownEntryTypeError,
                "No typed payload loaded for Ledger Entry type #{entry_type.inspect} " \
                "version #{type_version}. Pass the .graphql file declaring its " \
                'addLedgerEntry operation to FragmentClient::TypedEntries.load.'
        end
      end

      # Every loaded payload class, keyed by `[entry type, version]`.
      sig { returns(T::Hash[[String, Integer], T.class_of(FragmentClient::TypedLedgerEntry)]) }
      def registry
        @registry ||= T.let({}, T.nilable(T::Hash[[String, Integer],
                                                  T.class_of(FragmentClient::TypedLedgerEntry)]))
      end

      # Forget every loaded payload class and remove the constants defined for
      # them. For tests; a normal process loads once and keeps them.
      sig { void }
      def reset!
        defined_constants.each do |namespace, name|
          namespace.send(:remove_const, name) if namespace.const_defined?(name, false)
        end
        defined_constants.clear
        registry.clear
      end

      # Convert typed payloads and raw hashes alike into `AddLedgerEntryInput`
      # hashes, preserving order (spec 3.1, 3.5).
      #
      # Raw hashes pass through untouched, so a caller who explicitly puts `null`
      # in one gets `null` on the wire. That asymmetry with spec 3.2 is
      # deliberate: the omission rule is a property of the typed payloads.
      sig { params(entries: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
      def to_entry_inputs(entries)
        entries.map do |entry|
          entry.is_a?(FragmentClient::TypedLedgerEntry) ? entry.to_entry_input : entry
        end
      end

      sig { returns(Logger) }
      def logger
        FragmentClient.configuration.logger
      end

      sig { returns(Thread::Mutex) }
      def lock
        @lock ||= T.let(Thread::Mutex.new, T.nilable(Thread::Mutex))
      end

      # `[namespace, constant name]` for every class {load} defined, so {reset!}
      # can undo exactly those and nothing else.
      sig { returns(T::Array[[Module, String]]) }
      def defined_constants
        @defined_constants ||= T.let([], T.nilable(T::Array[[Module, String]]))
      end

      # --- Derivation (spec 2) ------------------------------------------------

      # Recover a spec for every typed entry operation in a parsed document,
      # deduplicated on identity.
      sig { params(document: GraphQL::Language::Nodes::Document).returns(T::Array[EntrySpec]) }
      def extract(document)
        specs = T.let({}, T::Hash[[String, Integer], EntrySpec])

        document.definitions.each do |definition|
          next unless definition.is_a?(GraphQL::Language::Nodes::OperationDefinition)

          spec = extract_spec(definition)
          next if spec.nil?

          # Two operations may legitimately map to one identity, e.g. a second
          # operation with a different selection set. The CLI and API guarantee
          # no two Ledger Entries share a (type, version) pair, so such
          # operations necessarily declare the same parameters. First in input
          # order wins (spec 2.2).
          existing = specs[spec.identity]
          if existing
            warn_on_conflict(existing, spec)
            next
          end

          specs[spec.identity] = spec
        end

        specs.values
      end

      # Recover one spec, or `nil` if this operation is not a typed entry
      # operation (spec 2.1).
      #
      # Anything that fails a condition is skipped silently rather than treated
      # as an error -- that is what excludes the SDK's own `AddLedgerEntry` and
      # `AddLedgerEntryRuntime`, whose `type` comes from a variable.
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T.nilable(EntrySpec))
      end
      def extract_spec(operation)
        name = operation.name
        return nil if name.nil?

        entry = entry_argument(operation)
        return nil if entry.nil?

        # A literal `type` is what makes an operation entry-type-specific.
        # Without it there is nothing to key a payload on.
        entry_type = object_field(entry, 'type')
        return nil unless entry_type.is_a?(String)

        version = object_field(entry, 'typeVersion')

        EntrySpec.new(
          entry_type: entry_type,
          type_version: version.is_a?(Integer) ? version : DEFAULT_TYPE_VERSION,
          operation_name: name,
          parameters: extract_parameters(object_field(entry, 'parameters'), operation)
        )
      end

      # The inline `entry:` object of a single-field `addLedgerEntry` mutation.
      #
      # `nil` for anything else: a query, a multi-field selection, a fragment
      # spread at the root, or an `entry` passed as a variable rather than
      # written inline.
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T.nilable(GraphQL::Language::Nodes::InputObject))
      end
      # One guard per numbered condition in spec 2.1. Collapsing them would hide
      # which condition rejected an operation, and that mapping is the point.
      # rubocop:disable Metrics/CyclomaticComplexity
      def entry_argument(operation)
        return nil unless operation.operation_type == 'mutation'

        selections = operation.selections
        return nil unless selections.length == 1

        root = selections.first
        return nil unless root.is_a?(GraphQL::Language::Nodes::Field)
        return nil unless root.name == ADD_LEDGER_ENTRY_FIELD

        argument = root.arguments.find { |a| a.name == 'entry' }
        value = argument&.value
        value.is_a?(GraphQL::Language::Nodes::InputObject) ? value : nil
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # The value of one field of an inline object literal, or `nil` if the field
      # is absent. A field written as `null` yields a `NullValue` node rather
      # than `nil`, so the two stay distinguishable.
      sig do
        params(object: GraphQL::Language::Nodes::InputObject, name: String).returns(T.untyped)
      end
      def object_field(object, name)
        object.arguments.find { |argument| argument.name == name }&.value
      end

      # Recover the typed parameters bound to the entry's `parameters` object
      # (spec 2.3).
      #
      # An absent `parameters`, or one passed as a variable rather than written
      # inline, yields no typed parameters. The payload is still defined, with
      # `parameters` falling back to an untyped hash.
      sig do
        params(node: T.untyped, operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T::Array[Parameter])
      end
      def extract_parameters(node, operation)
        return [] unless node.is_a?(GraphQL::Language::Nodes::InputObject)

        types = variable_types(operation)
        taken = T.let({}, T::Hash[Symbol, String])

        node.arguments.filter_map do |argument|
          value = argument.value
          # Only variable-bound parameters are typeable. One hardcoded in the
          # operation is already fixed by it and must not become a field.
          next unless value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)

          type = types[value.name]
          if type.nil?
            # An operation may reference an undeclared variable; graphql-client
            # rejects that at parse time, but this module also runs over
            # documents it never sees.
            logger.warn(
              "Fragment: parameter #{argument.name.inspect} in operation " \
              "#{operation.name} is bound to undeclared variable $#{value.name}; " \
              'treating it as an optional untyped parameter.'
            )
          end

          Parameter.new(
            wire_name: argument.name,
            name: local_name(argument.name, taken, operation),
            graphql_type: type&.to_query_string || 'JSON',
            required: type.is_a?(GraphQL::Language::Nodes::NonNullType)
          )
        end
      end

      # Map variable name to its declared type node.
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T::Hash[String, T.untyped])
      end
      def variable_types(operation)
        operation.variables.to_h { |definition| [definition.name, definition.type] }
      end

      # --- Naming (spec 2.5) -------------------------------------------------

      # The keyword argument and reader name for a parameter.
      #
      # Schema parameter names are kept verbatim rather than snake_cased, which
      # is what the rest of this SDK already does with GraphQL variables --
      # `client.create_ledger(schemaKey: ...)`. Keeping them verbatim also means
      # `user_id` and `userId` stay distinct instead of colliding on one
      # identifier, which is the hazard spec 2.5 warns about.
      #
      # A name is escaped with a trailing underscore only when it is already
      # taken: by a method the payload class inherits (`class`, `hash`), by a
      # common field of its own (`posted`), or by an earlier parameter. `taken`
      # is mutated so later parameters see the names already claimed.
      sig do
        params(wire_name: String, taken: T::Hash[Symbol, String],
               operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(Symbol)
      end
      def local_name(wire_name, taken, operation)
        name = wire_name.to_sym
        return claim(name, wire_name, taken) unless taken.key?(name) || reserved?(name)

        # The first occurrence in source order keeps the plain name and later
        # ones are suffixed, the same way class names are disambiguated above.
        candidate = :"#{wire_name}_"
        counter = 2
        while taken.key?(candidate) || reserved?(candidate)
          candidate = :"#{wire_name}_#{counter}"
          counter += 1
        end

        # The caller ends up using a name they did not choose, so say so. The
        # wire payload is unaffected either way.
        clash = taken[name]
        reason = clash ? "already used by parameter #{clash.inspect}" : 'reserved by the payload class'
        logger.warn(
          "Fragment: parameter #{wire_name.inspect} of #{operation.name} cannot be exposed " \
          "under that name (#{reason}); it is available as #{candidate.inspect} instead. " \
          'The wire payload is unchanged.'
        )
        claim(candidate, wire_name, taken)
      end

      # Names a payload class already responds to, read by reflection rather
      # than hand-listed so adding a method to the base class cannot silently
      # start shadowing a Schema parameter.
      sig { params(name: Symbol).returns(T::Boolean) }
      def reserved?(name)
        FragmentClient::TypedLedgerEntry.method_defined?(name) ||
          FragmentClient::TypedLedgerEntry.private_method_defined?(name)
      end

      # A constant name for an entry type: `user-funds-account` -> `UserFundsAccount`.
      sig { params(entry_type: String).returns(String) }
      def constant_name(entry_type)
        parts = entry_type
                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                .split(/[^a-zA-Z\d]+/)
                .reject(&:empty?)
        name = parts.map { |part| part[0].to_s.upcase + T.must(part[1..]) }.join
        # A constant must start with a letter, so an entry type like `2fa_hold`
        # needs a prefix rather than dropping the leading digit.
        name.match?(/\A[A-Z]/) ? name : "Entry#{name}"
      end

      private

      sig { params(name: Symbol, wire_name: String, taken: T::Hash[Symbol, String]).returns(Symbol) }
      def claim(name, wire_name, taken)
        taken[name] = wire_name
        name
      end

      # Define one payload class per spec and register it.
      sig do
        params(specs: T::Array[EntrySpec], namespace: Module, origin: T.nilable(String))
          .returns(T::Array[T.class_of(FragmentClient::TypedLedgerEntry)])
      end
      def define(specs, namespace:, origin:)
        # Two threads booting clients at once -- Puma workers, a threaded job
        # runner -- would otherwise race on `const_set` and on the registry, and
        # one of the two payload classes would be lost with a redefinition
        # warning. Contended only during loading, which happens once.
        lock.synchronize { register(specs, namespace, origin) }
      end

      sig do
        params(specs: T::Array[EntrySpec], namespace: Module, origin: T.nilable(String))
          .returns(T::Array[T.class_of(FragmentClient::TypedLedgerEntry)])
      end
      def register(specs, namespace, origin)
        specs.map do |spec|
          existing = registry[spec.identity]
          if existing
            warn_on_conflict(existing.spec, spec)
            next existing
          end

          klass = FragmentClient::TypedLedgerEntry.build(spec, origin: origin)
          name = unique_constant_name(spec, namespace)
          namespace.const_set(name, klass)
          defined_constants << [namespace, name]
          registry[spec.identity] = klass
          klass
        end
      end

      # Two distinct entry types can pascal-case alike (`auth_hold`, `authHold`).
      # Fall back to the operation name, then a counter, so a payload is never
      # dropped. Pathological: it is the one place a class name depends on what
      # else is loaded, and it only triggers for Schemas that already have two
      # confusingly similar entry types.
      sig { params(spec: EntrySpec, namespace: Module).returns(String) }
      def unique_constant_name(spec, namespace)
        base = spec.class_name
        return base unless namespace.const_defined?(base, false)

        candidate = "#{base}#{constant_name(spec.operation_name)}"
        counter = 2
        while namespace.const_defined?(candidate, false)
          candidate = "#{base}#{counter}"
          counter += 1
        end
        logger.warn(
          "Fragment: Ledger Entry type #{spec.entry_type.inspect} v#{spec.type_version} " \
          "would be named #{base}, which is taken; it is available as #{candidate} instead."
        )
        candidate
      end

      # Same identity from two operations is expected and fine. Differing
      # parameters mean the `.graphql` is stale relative to the Schema, and the
      # payload that lost the race silently posts the wrong parameter set.
      sig { params(kept: EntrySpec, dropped: EntrySpec).void }
      def warn_on_conflict(kept, dropped)
        return if kept.same_parameters?(dropped)

        logger.warn(
          "Fragment: operations #{kept.operation_name} and #{dropped.operation_name} both " \
          "describe Ledger Entry type #{kept.entry_type.inspect} v#{kept.type_version} but " \
          "declare different parameters (#{kept.parameters.map(&:wire_name).inspect} vs " \
          "#{dropped.parameters.map(&:wire_name).inspect}). Keeping #{kept.operation_name}; " \
          'the operation documents are probably stale relative to the Schema.'
        )
      end
    end
  end
end
