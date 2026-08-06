# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

class FragmentClient
  # Base class for a typed `addLedgerEntries` payload. Abstract: one subclass per
  # `(entry type, typeVersion)` is built by {FragmentClient::TypedEntries.load}.
  #
  # A subclass declares one keyword argument and one reader per Schema parameter,
  # alongside the common `LedgerEntryInput` fields, and {#to_entry_input} reshapes
  # them into the nested `AddLedgerEntryInput` the API takes.
  #
  #     entry = FragmentClient::Entries::AuthCaptureV1.new(
  #       ik: 'ik-1', ledger_ik: 'prod', capture_amount: '100'
  #     )
  #     client.add_ledger_entries(entries: [entry])
  #
  # Section references are to `typed-batch-entries.md`; see
  # `docs/spec-conformance.md`.
  class TypedLedgerEntry
    extend T::Sig
    extend T::Helpers
    abstract!

    # The `LedgerEntryInput` fields every payload carries, whatever its entry type
    # (spec 2.3a). Fixed by `LedgerEntryInput`, not derived from the operation,
    # which binds only what its CLI version chose to expose.
    #
    # `lines` is absent deliberately: it cannot be combined with an entry that has
    # a `type`. `type`, `typeVersion` and `parameters` are derived, never supplied.
    COMMON_FIELDS = T.let(
      %i[ik ledger_ik posted description tags groups conditions].freeze,
      T::Array[Symbol]
    )

    class << self
      extend T::Sig

      # Build a payload class for one derived spec.
      sig do
        params(spec: FragmentClient::TypedEntries::EntrySpec, origin: T.nilable(String))
          .returns(T.class_of(TypedLedgerEntry))
      end
      def build(spec, origin: nil)
        klass = Class.new(self)
        klass.instance_variable_set(:@spec, spec)
        klass.instance_variable_set(:@source_path, origin)

        spec.parameters.each do |parameter|
          name = parameter.name
          klass.send(:define_method, name) do
            T.bind(self, TypedLedgerEntry)
            parameter_value(name)
          end
        end

        klass
      end

      # What this payload was derived from.
      sig { returns(FragmentClient::TypedEntries::EntrySpec) }
      def spec
        @spec = T.let(@spec, T.nilable(FragmentClient::TypedEntries::EntrySpec))
        @spec || raise(
          NotImplementedError,
          "#{self} has no derived spec. Typed payload classes are built by " \
          'FragmentClient::TypedEntries.load, not subclassed by hand.'
        )
      end

      sig { returns(String) }
      def entry_type
        spec.entry_type
      end

      sig { returns(Integer) }
      def type_version
        spec.type_version
      end

      # The Schema parameters, in source order (spec 2.4).
      sig { returns(T::Array[FragmentClient::TypedEntries::Parameter]) }
      def parameters
        spec.parameters
      end

      # The `.graphql` file this came from, if it came from one.
      sig { returns(T.nilable(String)) }
      def source_path
        @source_path = T.let(@source_path, T.nilable(String))
      end
    end

    sig { returns(String) }
    attr_reader :ik

    sig { returns(String) }
    attr_reader :ledger_ik

    # The optional common fields: `nil` when unset, so `&.` and truthiness behave
    # as usual. {#set?} is what separates "not set" from "set to nil".
    sig { returns(T.nilable(String)) }
    attr_reader :posted

    sig { returns(T.nilable(String)) }
    attr_reader :description

    sig { returns(T.nilable(T::Array[T.untyped])) }
    attr_reader :tags

    sig { returns(T.nilable(T::Array[T.untyped])) }
    attr_reader :groups

    sig { returns(T.nilable(T::Array[T.untyped])) }
    attr_reader :conditions

    # Optional fields default to the {FragmentClient::TypedEntries::UNSET} sentinel
    # rather than `nil`, so an omitted keyword can be told from an explicit `nil`
    # and left out of the payload (spec 3.2). It is converted to `nil` here and
    # never returned.
    #
    # Schema parameters arrive through `**parameters` under the names this class
    # declares. Presence and unknown names are checked here; their types come from
    # the RBI `tapioca dsl` generates.
    sig do
      params(
        ik: String,
        ledger_ik: String,
        posted: T.any(String, NilClass, FragmentClient::TypedEntries::Unset),
        description: T.any(String, NilClass, FragmentClient::TypedEntries::Unset),
        tags: T.any(T::Array[T.untyped], NilClass, FragmentClient::TypedEntries::Unset),
        groups: T.any(T::Array[T.untyped], NilClass, FragmentClient::TypedEntries::Unset),
        conditions: T.any(T::Array[T.untyped], NilClass, FragmentClient::TypedEntries::Unset),
        parameters: T.untyped
      ).void
    end
    # rubocop:disable Metrics/AbcSize -- one assignment per common field; `typed:
    # strict` rules out setting them in a loop.
    def initialize(ik:, ledger_ik:,
                   posted: FragmentClient::TypedEntries::UNSET,
                   description: FragmentClient::TypedEntries::UNSET,
                   tags: FragmentClient::TypedEntries::UNSET,
                   groups: FragmentClient::TypedEntries::UNSET,
                   conditions: FragmentClient::TypedEntries::UNSET,
                   **parameters)
      @ik = ik
      @ledger_ik = ledger_ik
      @parameters = T.let(validate(parameters), T::Hash[Symbol, T.untyped])
      @provided = T.let(Set.new(@parameters.keys + %i[ik ledger_ik]), T::Set[Symbol])
      @posted = T.let(record(:posted, posted), T.nilable(String))
      @description = T.let(record(:description, description), T.nilable(String))
      @tags = T.let(record(:tags, tags), T.nilable(T::Array[T.untyped]))
      @groups = T.let(record(:groups, groups), T.nilable(T::Array[T.untyped]))
      @conditions = T.let(record(:conditions, conditions), T.nilable(T::Array[T.untyped]))
    end
    # rubocop:enable Metrics/AbcSize

    # Whether the caller set `name` -- a common field or a parameter. The readers
    # report an omitted field and an explicit `nil` alike, so this is the only way
    # to tell them apart.
    sig { params(name: Symbol).returns(T::Boolean) }
    def set?(name)
      @provided.include?(name)
    end

    # Same class, same wire payload -- which includes agreeing on what is set.
    sig { params(other: T.untyped).returns(T::Boolean) }
    def ==(other)
      other.instance_of?(self.class) && other.to_entry_input == to_entry_input
    end

    alias eql? ==

    sig { returns(Integer) }
    def hash
      [self.class, to_entry_input].hash
    end

    # The `AddLedgerEntryInput` this payload posts (spec 3.1). Keys lexicographic
    # at every level except `parameters`, which keeps source order (spec 3.4).
    sig { returns(T::Hash[String, T.untyped]) }
    def to_entry_input
      { 'entry' => entry_input, 'ik' => @ik }
    end

    # The `parameters` payload, keyed by verbatim Schema parameter name -- so an
    # escaped parameter still travels under its own key (spec 2.5, 3.3).
    sig { returns(T::Hash[String, T.untyped]) }
    def entry_parameters
      self.class.parameters.each_with_object({}) do |parameter, out|
        out[parameter.wire_name] = @parameters[parameter.name] if @parameters.key?(parameter.name)
      end
    end

    sig { returns(String) }
    def inspect
      shown = COMMON_FIELDS.select { |name| set?(name) }
                           .map { |name| "#{name}: #{public_send(name).inspect}" }
      shown.concat(@parameters.map { |name, value| "#{name}: #{value.inspect}" })
      "#<#{self.class} #{shown.join(', ')}>"
    end

    private

    # Records that `name` was supplied, and unwraps the sentinel to `nil`.
    sig { params(name: Symbol, value: T.untyped).returns(T.untyped) }
    def record(name, value)
      return nil if value.is_a?(FragmentClient::TypedEntries::Unset)

      @provided << name
      value
    end

    sig { params(name: Symbol).returns(T.untyped) }
    def parameter_value(name)
      @parameters[name]
    end

    sig { returns(T::Hash[String, T.untyped]) }
    def entry_input
      input = T.let({}, T::Hash[String, T.untyped])
      input['conditions'] = @conditions if set?(:conditions)
      input['description'] = @description if set?(:description)
      input['groups'] = @groups if set?(:groups)
      input['ledger'] = { 'ik' => @ledger_ik }
      # Always present: derived rather than supplied, so it has no unset state.
      input['parameters'] = entry_parameters
      input['posted'] = @posted if set?(:posted)
      input['tags'] = @tags if set?(:tags)
      input['type'] = self.class.entry_type
      input['typeVersion'] = self.class.type_version
      input
    end

    sig { params(supplied: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def validate(supplied)
      reject_unknown(supplied)
      require_declared(supplied)
      supplied
    end

    sig { params(supplied: T::Hash[Symbol, T.untyped]).void }
    def reject_unknown(supplied)
      known = self.class.parameters.map(&:name)
      unknown = supplied.keys - known
      return if unknown.empty?

      raise ArgumentError,
            "unknown keyword#{plural(unknown)}: #{list(unknown)} for #{describe}. " \
            "Declared parameters: #{known.empty? ? '(none)' : list(known)}."
    end

    sig { params(supplied: T::Hash[Symbol, T.untyped]).void }
    def require_declared(supplied)
      missing = self.class.parameters
                    .select { |parameter| parameter.required && !supplied.key?(parameter.name) }
                    .map(&:name)
      return if missing.empty?

      raise ArgumentError, "missing keyword#{plural(missing)}: #{list(missing)} for #{describe}."
    end

    sig { returns(String) }
    def describe
      "#{self.class.entry_type.inspect} v#{self.class.type_version}"
    end

    sig { params(names: T::Array[Symbol]).returns(String) }
    def plural(names)
      names.length == 1 ? '' : 's'
    end

    sig { params(names: T::Array[Symbol]).returns(String) }
    def list(names)
      names.map(&:inspect).join(', ')
    end
  end
end
