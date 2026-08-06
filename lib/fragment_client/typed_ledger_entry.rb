# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

class FragmentClient
  # Base class for a strongly-typed `addLedgerEntries` payload.
  #
  # One subclass is built per `(entry type, typeVersion)` pair by
  # {FragmentClient::TypedEntries.load}; this class is never instantiated
  # directly. A subclass declares one keyword argument and one reader per Schema
  # parameter, alongside the common `LedgerEntryInput` fields every entry has,
  # and {#to_entry_input} reshapes those flat fields into the nested
  # `AddLedgerEntryInput` the API expects.
  #
  #     entry = FragmentClient::Entries::AuthCaptureV1.new(
  #       ik: 'ik-1', ledger_ik: 'prod', capture_amount: '100'
  #     )
  #     client.add_ledger_entries(entries: [entry])
  #
  # Section references are to the shared `typed-batch-entries.md` specification;
  # see `docs/spec-conformance.md`.
  class TypedLedgerEntry
    extend T::Sig
    extend T::Helpers
    abstract!

    # The `LedgerEntryInput` fields every payload carries, regardless of entry
    # type (spec 2.3a).
    #
    # Fixed by `LedgerEntryInput`, deliberately *not* derived from the source
    # operation. An operation binds only the entry fields the CLI chose to
    # expose, and that choice has already changed between CLI versions -- one
    # generation binds `tags`, `groups` and `conditions` while another binds
    # `typeVersion` instead, and neither binds `description`. The operation is a
    # derivation input, never the transport: a payload travels as an
    # `AddLedgerEntryInput` on `addLedgerEntries`, so what the operation binds
    # places no limit on what the payload may carry.
    #
    # `lines` is the one `LedgerEntryInput` field a payload must not expose,
    # because it cannot be combined with an entry that has a `type`. `type`,
    # `typeVersion` and `parameters` are derived and never caller-supplied.
    COMMON_FIELDS = T.let(
      %i[ik ledger_ik posted description tags groups conditions].freeze,
      T::Array[Symbol]
    )

    class << self
      extend T::Sig

      # Build a payload class for one derived spec. Called by
      # {FragmentClient::TypedEntries.load}.
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
            # The block runs as an instance method, but Sorbet reads its `self`
            # from the enclosing scope, which here is the class.
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

      # The `.graphql` document this was derived from, when it came from a file.
      sig { returns(T.nilable(String)) }
      def source_path
        @source_path = T.let(@source_path, T.nilable(String))
      end
    end

    sig { returns(String) }
    attr_reader :ik

    sig { returns(String) }
    attr_reader :ledger_ik

    # The optional common fields. Plain `nil` when unset, so a reader behaves the
    # way a Ruby caller expects: `entry.posted&.length` and `if entry.posted` both
    # do the obvious thing. Ask {#set?} when the difference between "not set" and
    # "set to nil" matters, which is only when reading back what you built.
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

    # Optional fields default to {FragmentClient::TypedEntries::UNSET} rather than
    # `nil` so that an omitted keyword can be told from an explicit `nil` and left
    # out of the payload entirely (spec 3.2).
    #
    # That sentinel is an implementation detail of this constructor and goes no
    # further: it is recorded and converted to `nil` immediately, so no reader ever
    # hands one back. Returning it would mean every caller had to know about it to
    # write a truthiness test correctly, and only the wire format needs to.
    #
    # Schema parameters arrive through `**parameters`, keyed by the names this
    # payload's class declares. Sorbet checks those names and their types from
    # the RBI the Tapioca compiler generates; the checks here are what a caller
    # without Sorbet gets.
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
    # rubocop:disable Metrics/AbcSize -- one assignment per common field. A loop
    # over them would mean setting instance variables dynamically, which
    # `typed: strict` does not allow.
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
      # `ik` and `ledger_ik` are required, so they are always set.
      @provided = T.let(Set.new(@parameters.keys + %i[ik ledger_ik]), T::Set[Symbol])
      @posted = T.let(record(:posted, posted), T.nilable(String))
      @description = T.let(record(:description, description), T.nilable(String))
      @tags = T.let(record(:tags, tags), T.nilable(T::Array[T.untyped]))
      @groups = T.let(record(:groups, groups), T.nilable(T::Array[T.untyped]))
      @conditions = T.let(record(:conditions, conditions), T.nilable(T::Array[T.untyped]))
    end
    # rubocop:enable Metrics/AbcSize

    # Whether the caller set `name`, which may be a common field or a parameter.
    #
    # The only way to tell an omitted field from one set to `nil`, since the
    # readers report both as `nil`.
    sig { params(name: Symbol).returns(T::Boolean) }
    def set?(name)
      @provided.include?(name)
    end

    # Two payloads are equal when they are the same class and would post the same
    # thing -- including agreeing on which fields are set at all.
    sig { params(other: T.untyped).returns(T::Boolean) }
    def ==(other)
      other.instance_of?(self.class) && other.to_entry_input == to_entry_input
    end

    alias eql? ==

    sig { returns(Integer) }
    def hash
      [self.class, to_entry_input].hash
    end

    # The `AddLedgerEntryInput` this payload posts (spec 3.1).
    #
    # Keys are emitted in lexicographic order at every level except
    # `parameters`, which keeps source order -- the canonical ordering of the
    # spec's strict equivalence profile (spec 3.4).
    sig { returns(T::Hash[String, T.untyped]) }
    def to_entry_input
      { 'entry' => entry_input, 'ik' => @ik }
    end

    # The `parameters` payload, keyed by Schema parameter name.
    #
    # Names go on the wire verbatim, so a parameter this class had to expose
    # under an escaped name still carries its own value under its own key
    # (spec 2.5, 3.3).
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

    # Note the sentinel, then forget it: a field the caller omitted is `nil` from
    # here on, and {#set?} is what remembers the difference.
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

    # Keys in lexicographic order, omitting anything unset and keeping an explicit
    # `nil` as `null` (spec 3.2, 3.4).
    sig { returns(T::Hash[String, T.untyped]) }
    def entry_input
      input = T.let({}, T::Hash[String, T.untyped])
      input['conditions'] = @conditions if set?(:conditions)
      input['description'] = @description if set?(:description)
      input['groups'] = @groups if set?(:groups)
      input['ledger'] = { 'ik' => @ledger_ik }
      # Always present, even when empty: `parameters` is derived from the entry
      # type rather than supplied, so there is no unset state to omit.
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
