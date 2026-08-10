# typed: strict
# frozen_string_literal: true

require 'graphql'
require 'logger'
require 'sorbet-runtime'

require 'fragment_client/typed_ledger_entry'

class FragmentClient
  # Namespace holding the derived payload classes, e.g.
  # `FragmentClient::Entries::AuthCaptureV1`.
  #
  # Every constant here is defined at load time by {FragmentClient::TypedEntries.load};
  # anything else would risk colliding with a Ledger Entry type.
  module Entries; end

  # Derives typed `addLedgerEntries` payloads from the per-entry-type
  # `addLedgerEntry` operations the Fragment CLI generates for a Schema.
  #
  # A generated operation names the entry type as a string literal and binds each
  # parameter to a typed variable, which is what `addLedgerEntries` alone cannot
  # express: its `parameters` is an opaque `JSON` scalar.
  #
  #     FragmentClient::TypedEntries.load('app/graphql/entries.graphql')
  #     entry = FragmentClient::Entries::AuthCaptureV1.new(
  #       ik: 'ik-1', ledger_ik: 'prod', capture_amount: '100'
  #     )
  #     client.add_ledger_entries(entries: [entry])
  #
  # Payload classes are built at load time, so Sorbet sees them only through the
  # RBI `bundle exec tapioca dsl` generates.
  #
  # Implements `typed-batch-entries.md` from `fragment-dev/graphql-queries`.
  # Section references throughout are to that spec; `docs/spec-conformance.md`
  # maps it onto this SDK and explains the choices.
  module TypedEntries
    extend T::Sig

    # The only field a typed entry operation may select (spec 2.1).
    ADD_LEDGER_ENTRY_FIELD = 'addLedgerEntry'

    # What an entry with no `typeVersion` resolves to server-side (spec 2.5).
    DEFAULT_TYPE_VERSION = 1

    # Marks a keyword the caller omitted, as distinct from one set to `nil`
    # (spec 3.2). Internal to {TypedLedgerEntry#initialize}; never returned.
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

      # The Schema's name for it, and the JSON key sent in `parameters` (spec 3.3).
      const :wire_name, String

      # The keyword argument and reader on the payload class. Differs from
      # `wire_name` only when that name is taken (spec 2.5).
      const :name, Symbol

      # The bound variable's GraphQL type as written, e.g. `String!`,
      # `[SafeString!]`. Read by the Tapioca compiler; unused at runtime.
      const :graphql_type, String

      # Whether the bound variable is non-null.
      const :required, T::Boolean

      sig { returns(T::Boolean) }
      def escaped?
        wire_name.to_sym != name
      end

      # By value. `T::Struct` otherwise compares by identity.
      sig { params(other: T.untyped).returns(T::Boolean) }
      def ==(other)
        other.is_a?(Parameter) && serialize == other.serialize
      end
    end

    # Everything needed to define one payload class.
    class EntrySpec < T::Struct
      extend T::Sig

      const :entry_type, String

      # Always concrete; an unpinned operation carries {DEFAULT_TYPE_VERSION}.
      const :type_version, Integer

      # The operation this came from. Names the class only on collision (spec 2.5).
      const :operation_name, String

      # In the order they appear in the source `parameters: {...}` (spec 2.4).
      const :parameters, T::Array[Parameter]

      # What a payload is keyed on: the pair, never the entry type alone, since
      # one type at two versions has two parameter sets (spec 2.2).
      sig { returns([String, Integer]) }
      def identity
        [entry_type, type_version]
      end

      # `<PascalEntryType>V<version>`. Always carries the version, and depends on
      # nothing but this payload's own identity (spec 2.5, 2.6).
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
      # Idempotent, and needs neither credentials nor network, so it is safe in an
      # initializer -- where `tapioca dsl` will see the classes.
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

      # The payload class for an entry type and version.
      #
      # @raise [UnknownEntryTypeError] if no document declaring it was loaded.
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

      # Forget every loaded payload class and remove its constant. For tests.
      sig { void }
      def reset!
        defined_constants.each do |namespace, name|
          namespace.send(:remove_const, name) if namespace.const_defined?(name, false)
        end
        defined_constants.clear
        registry.clear
      end

      # Convert typed payloads to `AddLedgerEntryInput` hashes, in order. Raw
      # hashes pass through untouched (spec 3.1, 3.5).
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
      # removes exactly those.
      sig { returns(T::Array[[Module, String]]) }
      def defined_constants
        @defined_constants ||= T.let([], T.nilable(T::Array[[Module, String]]))
      end

      # --- Derivation (spec 2) ------------------------------------------------

      # A spec per typed entry operation, deduplicated on identity.
      sig { params(document: GraphQL::Language::Nodes::Document).returns(T::Array[EntrySpec]) }
      def extract(document)
        specs = T.let({}, T::Hash[[String, Integer], EntrySpec])

        document.definitions.each do |definition|
          next unless definition.is_a?(GraphQL::Language::Nodes::OperationDefinition)

          spec = extract_spec(definition)
          next if spec.nil?

          # First in input order wins (spec 2.2).
          existing = specs[spec.identity]
          if existing
            warn_on_conflict(existing, spec)
            next
          end

          specs[spec.identity] = spec
        end

        specs.values
      end

      # One spec, or `nil` for anything that is not a typed entry operation.
      # Failing a condition is silent, not an error (spec 2.1).
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T.nilable(EntrySpec))
      end
      def extract_spec(operation)
        name = operation.name
        return nil if name.nil?

        entry = entry_argument(operation)
        return nil if entry.nil?

        # A literal `type` is what makes an operation entry-type-specific; a
        # variable one leaves nothing to key a payload on.
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

      # The inline `entry:` object of a single-field `addLedgerEntry` mutation, or
      # `nil` for a query, a multi-field selection, a root fragment spread, or an
      # `entry` passed as a variable.
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T.nilable(GraphQL::Language::Nodes::InputObject))
      end
      # One guard per numbered condition in spec 2.1.
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

      # One field of an inline object literal, or `nil` if absent. A field written
      # as `null` yields a `NullValue` node, not `nil`.
      sig do
        params(object: GraphQL::Language::Nodes::InputObject, name: String).returns(T.untyped)
      end
      def object_field(object, name)
        object.arguments.find { |argument| argument.name == name }&.value
      end

      # The typed parameters bound to the entry's `parameters` object (spec 2.3).
      # Empty when `parameters` is absent or passed as a variable.
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
          # A parameter the operation hardcodes is fixed by it, not caller-supplied.
          next unless value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)

          type = types[value.name]
          if type.nil?
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

      # Variable name to declared type node.
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
      # Verbatim, so `user_id` and `userId` stay distinct. Escaped with a trailing
      # underscore only when the name is already taken -- by an inherited method,
      # a common field, or an earlier parameter (spec 2.5). Mutates `taken`.
      sig do
        params(wire_name: String, taken: T::Hash[Symbol, String],
               operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(Symbol)
      end
      def local_name(wire_name, taken, operation)
        name = wire_name.to_sym
        return claim(name, wire_name, taken) unless taken.key?(name) || reserved?(name)

        candidate = :"#{wire_name}_"
        counter = 2
        while taken.key?(candidate) || reserved?(candidate)
          candidate = :"#{wire_name}_#{counter}"
          counter += 1
        end

        clash = taken[name]
        reason = clash ? "already used by parameter #{clash.inspect}" : 'reserved by the payload class'
        logger.warn(
          "Fragment: parameter #{wire_name.inspect} of #{operation.name} cannot be exposed " \
          "under that name (#{reason}); it is available as #{candidate.inspect} instead. " \
          'The wire payload is unchanged.'
        )
        claim(candidate, wire_name, taken)
      end

      # Names a payload already responds to. By reflection, so adding a method to
      # the base class cannot silently shadow a Schema parameter.
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
        # A constant must start with a letter: `2fa_hold` -> `Entry2faHold`.
        name.match?(/\A[A-Z]/) ? name : "Entry#{name}"
      end

      private

      sig { params(name: Symbol, wire_name: String, taken: T::Hash[Symbol, String]).returns(Symbol) }
      def claim(name, wire_name, taken)
        taken[name] = wire_name
        name
      end

      # Define and register one payload class per spec. Locked, because
      # concurrent client construction would otherwise race on `const_set`.
      sig do
        params(specs: T::Array[EntrySpec], namespace: Module, origin: T.nilable(String))
          .returns(T::Array[T.class_of(FragmentClient::TypedLedgerEntry)])
      end
      def define(specs, namespace:, origin:)
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

      # Two entry types can pascal-case alike (`auth_hold`, `authHold`); the
      # operation name and then a counter break the tie so neither is dropped.
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

      # Silent when two operations agree; differing parameters mean the `.graphql`
      # is stale relative to the Schema.
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
