# frozen_string_literal: true
# typed: true

require 'json'
require 'logger'
require 'minitest/autorun'
require 'stringio'
require 'fragment_client'

# Derivation and serialization rules of the shared `typed-batch-entries.md`
# specification that its language-neutral fixtures cannot express.
#
# The fixtures cover six of sixteen testable requirements; the rest are either
# recorded upstream as gaps or are per-SDK. These are those, so a rule with no
# shared fixture still has something that fails when it breaks.
class TypedEntriesTest < Minitest::Test
  def setup
    @warnings = StringIO.new
    logger = Logger.new(@warnings)
    logger.formatter = ->(_severity, _time, _progname, message) { "#{message}\n" }
    FragmentClient.configure { |config| config.logger = logger }
    FragmentClient::TypedEntries.reset!
  end

  def teardown
    FragmentClient::TypedEntries.reset!
    FragmentClient.instance_variable_set(:@configuration, nil)
    # webmock/minitest installs WebMock.reset! by aliasing Minitest::Test#teardown,
    # so a teardown here that skips super leaves its requests in the global journal.
    super
  end

  # --- Recognition (spec 2.1) ----------------------------------------------

  def test_non_qualifying_operations_are_skipped_silently
    # Each of these fails exactly one recognition condition.
    sources = {
      'a query rather than a mutation' => <<~GQL,
        query NotAMutation($ik: SafeString!, $amount: String!) {
          addLedgerEntry(ik: $ik, entry: {type: "t", parameters: {amount: $amount}}) { __typename }
        }
      GQL
      'an anonymous mutation' => <<~GQL,
        mutation {
          addLedgerEntry(ik: "x", entry: {type: "t"}) { __typename }
        }
      GQL
      'more than one selection' => <<~GQL,
        mutation TwoSelections($ik: SafeString!) {
          addLedgerEntry(ik: $ik, entry: {type: "t"}) { __typename }
          workspace { id }
        }
      GQL
      'a different root field' => <<~GQL,
        mutation NotAnEntry($ledger: LedgerMatchInput!) {
          deleteLedger(ledger: $ledger) { __typename }
        }
      GQL
      'an entry passed as a variable' => <<~GQL,
        mutation EntryByVariable($ik: SafeString!, $entry: LedgerEntryInput!) {
          addLedgerEntry(ik: $ik, entry: $entry) { __typename }
        }
      GQL
      'a type bound to a variable' => <<~GQL,
        mutation TypeByVariable($ik: SafeString!, $type: String!) {
          addLedgerEntry(ik: $ik, entry: {type: $type}) { __typename }
        }
      GQL
      'a fragment spread at the root' => <<~GQL,
        mutation SpreadAtRoot($ik: SafeString!) {
          ...PostIt
        }

        fragment PostIt on Mutation {
          addLedgerEntry(ik: "x", entry: {type: "t"}) { __typename }
        }
      GQL
      'no entry argument at all' => <<~GQL
        mutation NoEntryArgument($ik: SafeString!) {
          addLedgerEntry(ik: $ik) { __typename }
        }
      GQL
    }

    sources.each do |description, source|
      assert_empty FragmentClient::TypedEntries.load_string(source, namespace: Module.new),
                   "#{description} should be skipped"
    end

    assert_empty @warnings.string, 'skipping a non-qualifying operation must be silent'
  end

  def test_the_sdks_own_operations_yield_no_typed_payloads
    # The real regression guard for the rule above: `AddLedgerEntry` and
    # `AddLedgerEntryRuntime` both bind `type` to a variable, and an untyped
    # `parameters: $parameters` blob. Nothing in queries.graphql is derivable.
    specs = FragmentClient::TypedEntries.extract(
      GraphQL.parse(File.read(File.expand_path('../lib/queries.graphql', __dir__)))
    )

    assert_empty specs
  end

  def test_a_document_may_hold_definitions_that_are_not_operations
    # A `.graphql` file is free to declare fragments alongside its operations, and
    # a fragment is not an operation definition at all.
    klasses = load(<<~GQL)
      fragment EntryFields on LedgerEntry {
        id
        ik
      }

      mutation WithFragment($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {type: "with_fragment", parameters: {amount: $amount}}) {
          __typename
        }
      }
    GQL

    assert_equal 1, klasses.length
    assert_equal 'with_fragment', klasses.fetch(0).entry_type
  end

  def test_operation_name_is_irrelevant
    # No naming convention may be required. `PostAuthCapture` and friends are
    # informative only, and the derived name comes from the entry type.
    klass = load(<<~GQL).first
      mutation zzz_lowercase_and_underscored($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {type: "some_entry", parameters: {amount: $amount}}) {
          __typename
        }
      }
    GQL

    assert_equal 'some_entry', klass.entry_type
    assert_equal 'SomeEntryV1', klass.name.split('::').last
  end

  # --- Identity (spec 2.2) -------------------------------------------------

  def test_two_operations_with_one_identity_are_deduplicated
    klasses = load(<<~GQL)
      mutation First($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {type: "dup", parameters: {amount: $amount}}) { __typename }
      }

      mutation Second($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {type: "dup", typeVersion: 1, parameters: {amount: $amount}}) {
          __typename
          ... on AddLedgerEntryResult { isIkReplay }
        }
      }
    GQL

    # An unpinned operation and one pinning version 1 share an identity, so this
    # is one payload, not two.
    assert_equal 1, klasses.length
    assert_empty @warnings.string, 'identical parameter sets are expected, not a conflict'
  end

  def test_conflicting_parameter_sets_for_one_identity_warn_and_keep_the_first
    klasses = load(<<~GQL)
      mutation First($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {type: "stale", parameters: {amount: $amount}}) { __typename }
      }

      mutation Second($ik: SafeString!, $amount: String!, $fee: String!) {
        addLedgerEntry(ik: $ik, entry: {type: "stale", parameters: {amount: $amount, fee: $fee}}) {
          __typename
        }
      }
    GQL

    assert_equal %w[amount], klasses.fetch(0).parameters.map(&:wire_name)
    assert_match(/First and Second/, @warnings.string)
    assert_match(/probably stale/, @warnings.string)
  end

  def test_identity_is_the_pair_not_the_type
    klasses = load(File.read(fixture('002-type-versions', 'input.graphql')))

    assert_equal(%w[UserFundsAccountV1 UserFundsAccountV2],
                 klasses.map { |klass| klass.name.split('::').last })
    assert_equal %w[amount], FragmentClient::TypedEntries.fetch('user-funds-account', 1)
                                                         .parameters.map(&:wire_name)
    assert_equal %w[amount feeAmount], FragmentClient::TypedEntries.fetch('user-funds-account', 2)
                                                                   .parameters.map(&:wire_name)
  end

  # --- Parameters (spec 2.3) -----------------------------------------------

  def test_a_parameter_fixed_by_the_operation_is_not_caller_supplied
    klass = load(<<~GQL).first
      mutation PartlyFixed($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "partly_fixed",
          parameters: {mode: "always_this", count: 3, amount: $amount}
        }) { __typename }
      }
    GQL

    # `mode` and `count` are fixed by the operation. Exposing them would let a
    # caller override a value the operation deliberately pinned.
    assert_equal %w[amount], klass.parameters.map(&:wire_name)
    refute_includes klass.new(ik: 'i', ledger_ik: 'l', amount: '1').entry_parameters.keys, 'mode'
  end

  def test_requiredness_comes_from_the_variable_not_the_parameter_name
    # `amount` is bound to an optional variable and `note` to a required one, so
    # a generator reading the field names rather than the variable definitions
    # would get both backwards.
    klass = load(<<~GQL).first
      mutation Mixed($ik: SafeString!, $amount: String, $note: String!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "mixed", parameters: {amount: $amount, note: $note}
        }) { __typename }
      }
    GQL

    assert_equal({ 'amount' => false, 'note' => true },
                 klass.parameters.to_h { |p| [p.wire_name, p.required] })
    assert_equal({ 'amount' => 'String', 'note' => 'String!' },
                 klass.parameters.to_h { |p| [p.wire_name, p.graphql_type] })

    # Which means only `note` is enforced.
    klass.new(ik: 'i', ledger_ik: 'l', note: 'n')
    assert_raises(ArgumentError) { klass.new(ik: 'i', ledger_ik: 'l', amount: '1') }
  end

  def test_a_parameter_bound_to_an_undeclared_variable_warns_and_stays_optional
    # graphql-client rejects an undeclared variable at parse time, but this module
    # also runs over documents it never sees. Dropping the parameter would lose a
    # value silently; keeping it untyped is the lesser harm, so long as it is said.
    klass = load(<<~GQL).first
      mutation Undeclared($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "undeclared", parameters: {amount: $nowhere}
        }) { __typename }
      }
    GQL

    assert_equal %w[amount], klass.parameters.map(&:wire_name)
    refute klass.parameters.fetch(0).required
    assert_equal 'JSON', klass.parameters.fetch(0).graphql_type
    assert_match(/bound to undeclared variable \$nowhere/, @warnings.string)
  end

  def test_validation_messages_read_correctly_for_one_and_for_several
    klass = load(<<~GQL).first
      mutation Several($ik: SafeString!, $a: String!, $b: String!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "several", parameters: {a: $a, b: $b}
        }) { __typename }
      }
    GQL

    one = assert_raises(ArgumentError) { klass.new(ik: 'i', ledger_ik: 'l', a: '1') }
    assert_match(/missing keyword: :b for "several" v1/, one.message)

    several = assert_raises(ArgumentError) { klass.new(ik: 'i', ledger_ik: 'l') }
    assert_match(/missing keywords: :a, :b/, several.message)
  end

  def test_an_unknown_keyword_on_a_parameterless_payload_says_so
    klass = load(<<~GQL).first
      mutation NoParams($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "no_params"}) { __typename }
      }
    GQL

    error = assert_raises(ArgumentError) { klass.new(ik: 'i', ledger_ik: 'l', amount: '1') }

    # Listing an empty set would read as though the payload declared nothing
    # *yet*, rather than declaring nothing at all.
    assert_match(/Declared parameters: \(none\)\./, error.message)
  end

  def test_a_payload_is_still_derived_without_typed_parameters
    [
      'mutation NoParameters($ik: SafeString!) { addLedgerEntry(ik: $ik, entry: {type: "bare"}) ' \
      '{ __typename } }',
      'mutation OpaqueParameters($ik: SafeString!, $parameters: JSON!) { addLedgerEntry(ik: $ik, ' \
      'entry: {type: "bare", parameters: $parameters}) { __typename } }'
    ].each do |source|
      klass = load(source, namespace: Module.new).first

      refute_nil klass, "#{source} should still yield a payload"
      assert_empty klass.parameters
      assert_empty(klass.new(ik: 'i', ledger_ik: 'l').entry_parameters)
    end
  end

  # --- Common fields (spec 2.3a) -------------------------------------------

  def test_every_common_field_reaches_the_wire
    # Derived from `LedgerEntryInput`, deliberately not from the operation --
    # which here binds none of them.
    klass = load(<<~GQL).first
      mutation Minimal($ik: SafeString!, $ledgerIk: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {ledger: {ik: $ledgerIk}, type: "common"}) { __typename }
      }
    GQL

    entry = klass.new(
      ik: 'ik-1', ledger_ik: 'prod', posted: '2026-01-01T00:00:00Z', description: 'a description',
      tags: [{ 'key' => 'k', 'value' => 'v' }], groups: [{ 'key' => 'g', 'value' => 'v' }],
      conditions: [{ 'account' => { 'path' => 'assets' } }]
    ).to_entry_input

    assert_equal %w[entry ik], entry.keys.sort
    assert_equal(
      %w[conditions description groups ledger parameters posted tags type typeVersion],
      entry.fetch('entry').keys.sort
    )
    assert_equal 'a description', entry.dig('entry', 'description')
    assert_equal [{ 'key' => 'k', 'value' => 'v' }], entry.dig('entry', 'tags')
  end

  def test_lines_is_not_exposed
    # `lines` cannot be combined with an entry that has a `type`, so a payload
    # must not offer it. Nor may the derived fields be caller-supplied.
    klass = load(<<~GQL).first
      mutation Lines($ik: SafeString!) { addLedgerEntry(ik: $ik, entry: {type: "l"}) { __typename } }
    GQL

    %i[lines type typeVersion parameters].each do |field|
      assert_raises(ArgumentError, "#{field} must not be accepted") do
        klass.new(ik: 'i', ledger_ik: 'l', **{ field => 'x' })
      end
    end
  end

  # --- Naming and escaping (spec 2.5) --------------------------------------

  def test_an_unpinned_version_is_normalised_to_one_in_the_name_and_on_the_wire
    klass = load(<<~GQL).first
      mutation Unpinned($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "unpinned"}) { __typename }
      }
    GQL

    # A payload called V1 that posted no version at all would mislead every
    # reader of it, so the name and the wire agree.
    assert_equal 'UnpinnedV1', klass.name.split('::').last
    assert_equal 1, klass.type_version
    assert_equal 1, klass.new(ik: 'i', ledger_ik: 'l').to_entry_input.dig('entry', 'typeVersion')
  end

  def test_a_name_does_not_depend_on_which_other_operations_are_loaded
    # Adding a second version later must not rename the first. Loading v2 alone
    # yields the same name it has when v1 is present, and vice versa.
    only_v2 = load(<<~GQL, namespace: Module.new).first
      mutation OnlyV2($ik: SafeString!, $amount: String!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "user-funds-account", typeVersion: 2, parameters: {amount: $amount}
        }) { __typename }
      }
    GQL

    assert_equal 'UserFundsAccountV2', only_v2.name.split('::').last

    FragmentClient::TypedEntries.reset!
    both = load(File.read(fixture('002-type-versions', 'input.graphql')), namespace: Module.new)

    assert_equal 'UserFundsAccountV2', both.fetch(1).name.split('::').last
  end

  def test_escaping_warns_and_never_changes_the_wire_name
    klass = load(File.read(fixture('003-reserved-names', 'input.graphql'))).first

    assert_equal({ 'type' => :type, 'class' => :class_, 'json' => :json,
                   'posted' => :posted_, 'userId' => :userId },
                 klass.parameters.to_h { |p| [p.wire_name, p.name] })

    # `class` would shadow `Object#class` and `posted` a common field of the
    # payload itself. Everything else is kept verbatim -- including `userId`,
    # because snake_casing it would collide with a Schema's own `user_id`.
    assert_match(/parameter "class" of PostReserved cannot be exposed under that name/,
                 @warnings.string)
    assert_match(/available as :posted_ instead/, @warnings.string)
    refute_match(/"userId"/, @warnings.string)

    parameters = klass.new(
      ik: 'r-1', ledger_ik: 'prod', type: 't', class_: 'c', json: 'j', posted_: 'p', userId: 'u'
    ).entry_parameters

    assert_equal({ 'type' => 't', 'class' => 'c', 'json' => 'j', 'posted' => 'p', 'userId' => 'u' },
                 parameters)
  end

  def test_colliding_local_names_stay_distinct_and_each_carries_its_own_value
    # `posted` escapes to `posted_`, which the Schema also declares. Silently
    # keeping one declaration would put a single value under both wire keys --
    # the hazard the spec names Python for.
    klass = load(<<~GQL).first
      mutation Collide($ik: SafeString!, $a: String!, $b: String!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "collide", parameters: {posted: $a, posted_: $b}
        }) { __typename }
      }
    GQL

    assert_equal({ 'posted' => :posted_, 'posted_' => :posted__ },
                 klass.parameters.to_h { |p| [p.wire_name, p.name] })

    parameters = klass.new(ik: 'i', ledger_ik: 'l', posted_: 'first', posted__: 'second')
                      .entry_parameters

    assert_equal({ 'posted' => 'first', 'posted_' => 'second' }, parameters)
  end

  def test_a_third_colliding_local_name_falls_back_to_a_counter
    # `posted_` is claimed first, so `posted` cannot use it as its escape and has
    # to keep counting. Without the counter the two would land on one identifier
    # and one wire key would take the other's value.
    klass = load(<<~GQL).first
      mutation ThreeWay($ik: SafeString!, $a: String!, $b: String!) {
        addLedgerEntry(ik: $ik, entry: {
          type: "three_way", parameters: {posted_: $a, posted: $b}
        }) { __typename }
      }
    GQL

    # rubocop:disable Naming/VariableNumber -- these are generated names, not ours
    assert_equal({ 'posted_' => :posted_, 'posted' => :posted_2 },
                 klass.parameters.to_h { |p| [p.wire_name, p.name] })
    assert_equal({ 'posted_' => 'first', 'posted' => 'second' },
                 klass.new(ik: 'i', ledger_ik: 'l', posted_: 'first', posted_2: 'second')
                      .entry_parameters)
    # rubocop:enable Naming/VariableNumber
  end

  def test_entry_types_that_share_a_constant_name_are_both_kept
    klasses = load(<<~GQL)
      mutation Snake($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "auth_hold"}) { __typename }
      }

      mutation Camel($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "authHold"}) { __typename }
      }
    GQL

    assert_equal 2, klasses.length
    assert_equal %w[auth_hold authHold], klasses.map(&:entry_type)
    refute_equal klasses.fetch(0).name, klasses.fetch(1).name
    assert_match(/would be named AuthHoldV1, which is taken/, @warnings.string)
  end

  def test_a_third_colliding_constant_name_falls_back_to_a_counter
    # Three entry types that pascal-case alike, from operations that also
    # pascal-case alike, so neither the plain name nor the operation-name fallback
    # is available. Pathological, but a payload must never be dropped.
    klasses = load(<<~GQL)
      mutation Dup($ik: SafeString!) { addLedgerEntry(ik: $ik, entry: {type: "auth_hold"}) { __typename } }
      mutation Dup($ik: SafeString!) { addLedgerEntry(ik: $ik, entry: {type: "authHold"}) { __typename } }
      mutation Dup($ik: SafeString!) { addLedgerEntry(ik: $ik, entry: {type: "auth-hold"}) { __typename } }
    GQL

    assert_equal 3, klasses.length
    assert_equal 3, klasses.map { |klass| klass.name.split('::').last }.uniq.length
    assert_equal %w[auth_hold authHold auth-hold], klasses.map(&:entry_type)
  end

  def test_a_constant_name_always_starts_with_a_letter
    klass = load(<<~GQL).first
      mutation Digits($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "2fa_challenge"}) { __typename }
      }
    GQL

    assert_equal 'Entry2faChallengeV1', klass.name.split('::').last
  end

  # --- Omission (spec 3.2) -------------------------------------------------

  def test_unset_is_omitted_and_explicit_nil_is_sent
    klass = load(<<~GQL).first
      mutation Optionals($ik: SafeString!, $required: String!, $optional: String) {
        addLedgerEntry(ik: $ik, entry: {
          type: "optionals", parameters: {required: $required, optional: $optional}
        }) { __typename }
      }
    GQL

    omitted = klass.new(ik: 'i', ledger_ik: 'l', required: 'yes').to_entry_input

    refute_includes omitted.fetch('entry').keys, 'description'
    refute_includes omitted.dig('entry', 'parameters').keys, 'optional'
    refute_match(/null/, JSON.generate(omitted))

    explicit = klass.new(
      ik: 'i', ledger_ik: 'l', required: 'yes', optional: nil, description: nil
    ).to_entry_input

    assert_nil explicit.dig('entry', 'description')
    assert_includes explicit.fetch('entry').keys, 'description'
    assert_equal({ 'required' => 'yes', 'optional' => nil }, explicit.dig('entry', 'parameters'))
  end

  def test_set_distinguishes_unset_from_nil
    klass = load(<<~GQL).first
      mutation SetCheck($ik: SafeString!, $optional: String) {
        addLedgerEntry(ik: $ik, entry: {
          type: "set_check", parameters: {optional: $optional}
        }) { __typename }
      }
    GQL

    unset = klass.new(ik: 'i', ledger_ik: 'l')

    refute unset.set?(:description)
    refute unset.set?(:optional)
    # The readers say nil either way; #set? is the only thing that separates them.
    # A caller who never asks gets Ruby's ordinary nil semantics.
    assert_nil unset.description
    assert_nil unset.optional

    explicit = klass.new(ik: 'i', ledger_ik: 'l', description: nil, optional: nil)

    assert explicit.set?(:description)
    assert explicit.set?(:optional)
    assert_nil explicit.description
    assert_nil explicit.optional
  end

  # --- Batch shape (spec 3.1, 3.5) -----------------------------------------

  def test_entry_order_is_preserved_and_raw_inputs_may_be_mixed_in
    klasses = load(File.read(fixture('002-type-versions', 'input.graphql')))
    v1 = klasses.fetch(0).new(ik: 'first', ledger_ik: 'prod', amount: '1')
    v2 = klasses.fetch(1).new(ik: 'third', ledger_ik: 'prod', amount: '2', feeAmount: '3')
    raw = { ik: 'second', entry: { ledger: { ik: 'prod' }, type: 'raw', posted: nil } }

    inputs = FragmentClient::TypedEntries.to_entry_inputs([v1, raw, v2])

    assert_equal(%w[first second third], inputs.map { |input| input[:ik] || input['ik'] })
    # A raw input passes through untouched, so a caller who explicitly puts
    # `null` in one gets `null` -- the accepted asymmetry with spec 3.2.
    assert_same raw, inputs.fetch(1)
  end

  # --- Loading (Ruby-specific) ---------------------------------------------

  def test_loading_is_idempotent_and_reuses_the_same_class
    source = <<~GQL
      mutation Twice($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "twice"}) { __typename }
      }
    GQL

    first = FragmentClient::TypedEntries.load_string(source).first
    second = FragmentClient::TypedEntries.load_string(source).first

    assert_same first, second
    assert_equal 1, FragmentClient::TypedEntries.registry.length
    assert_empty @warnings.string
  end

  def test_load_reads_files_and_records_where_a_payload_came_from
    path = fixture('001-basic', 'input.graphql')
    klass = FragmentClient::TypedEntries.load(path).first

    assert_equal 'auth_capture', klass.entry_type
    assert_equal path, klass.source_path
  end

  def test_fetching_an_unloaded_entry_type_says_what_to_do
    error = assert_raises(FragmentClient::TypedEntries::UnknownEntryTypeError) do
      FragmentClient::TypedEntries.fetch('never_loaded')
    end

    assert_match(/No typed payload loaded for Ledger Entry type "never_loaded" version 1/,
                 error.message)
    assert_match(/TypedEntries\.load/, error.message)
  end

  def test_payload_classes_are_registered_under_the_entries_namespace_by_default
    FragmentClient::TypedEntries.load_string(<<~GQL)
      mutation Namespaced($ik: SafeString!) {
        addLedgerEntry(ik: $ik, entry: {type: "namespaced"}) { __typename }
      }
    GQL

    assert FragmentClient::Entries.const_defined?(:NamespacedV1, false)
    assert_operator FragmentClient::Entries::NamespacedV1, :<, FragmentClient::TypedLedgerEntry
  end

  def test_the_base_class_cannot_be_used_directly
    assert_raises(NotImplementedError) { FragmentClient::TypedLedgerEntry.entry_type }
  end

  def test_readers_behave_like_ordinary_ruby_for_an_unset_field
    # The majority of Ruby callers do not run Sorbet and will reach for `&.` and a
    # truthiness test. Handing them a sentinel would make both of those wrong.
    klass = load(<<~GQL).first
      mutation Idiomatic($ik: SafeString!, $amount: String!, $fee: String) {
        addLedgerEntry(ik: $ik, entry: {
          type: "idiomatic", parameters: {amount: $amount, fee: $fee}
        }) { __typename }
      }
    GQL
    entry = klass.new(ik: 'i', ledger_ik: 'l', amount: '100')

    refute entry.posted, 'an unset field must be falsy'
    assert_nil entry.fee&.upcase, '&. must short-circuit on an unset parameter'
    assert_equal '-', [entry.posted, entry.description, entry.fee].map { |v| v || '-' }.uniq.first
  end

  def test_payloads_compare_by_value
    # A data object that only compares by identity is a nuisance to assert on, and
    # every Ruby caller expects otherwise.
    klass = load(<<~GQL).first
      mutation Comparable($ik: SafeString!, $amount: String!, $fee: String) {
        addLedgerEntry(ik: $ik, entry: {
          type: "comparable", parameters: {amount: $amount, fee: $fee}
        }) { __typename }
      }
    GQL
    build = ->(**extra) { klass.new(ik: 'i', ledger_ik: 'l', amount: '1', **extra) }

    assert_equal build.call, build.call
    assert_equal build.call.hash, build.call.hash
    assert_equal 1, [build.call, build.call].uniq.length
    refute_equal build.call, build.call(amount: '2')
    # Set-to-nil and never-set post different payloads, so they are not equal.
    refute_equal build.call, build.call(fee: nil)
  end

  def test_inspect_shows_what_was_set_and_nothing_else
    # The whole point of the unset sentinel is that "not set" and `nil` differ, so
    # a payload's own inspect has to make that visible rather than printing the
    # sentinel's object id or a wall of unset fields.
    klass = load(<<~GQL).first
      mutation Inspectable($ik: SafeString!, $amount: String!, $fee: String) {
        addLedgerEntry(ik: $ik, entry: {
          type: "inspectable", parameters: {amount: $amount, fee: $fee}
        }) { __typename }
      }
    GQL

    entry = klass.new(ik: 'ik-1', ledger_ik: 'prod', amount: '100', description: nil)

    assert_match(/InspectableV1 /, entry.inspect)
    assert_match(/ik: "ik-1"/, entry.inspect)
    assert_match(/description: nil/, entry.inspect)
    assert_match(/amount: "100"/, entry.inspect)
    refute_match(/posted/, entry.inspect)
    refute_match(/fee/, entry.inspect)
  end

  def test_the_unset_sentinel_never_escapes_the_constructor
    # It is the marker for an omitted keyword and nothing more. It still names
    # itself, because sorbet-runtime prints the default in a signature error.
    klass = load(<<~GQL).first
      mutation Sentinel($ik: SafeString!, $fee: String) {
        addLedgerEntry(ik: $ik, entry: {
          type: "sentinel", parameters: {fee: $fee}
        }) { __typename }
      }
    GQL
    entry = klass.new(ik: 'i', ledger_ik: 'l')

    [entry.fee, entry.posted, entry.description, entry.tags].each do |value|
      assert_nil value, 'the sentinel reached a caller'
    end
    refute_match(/UNSET/, entry.inspect)

    assert_equal 'FragmentClient::TypedEntries::UNSET',
                 FragmentClient::TypedEntries::UNSET.inspect
    assert_equal 'FragmentClient::TypedEntries::UNSET',
                 FragmentClient::TypedEntries::UNSET.to_s
  end

  private

  def load(source, namespace: FragmentClient::Entries)
    FragmentClient::TypedEntries.load_string(source, namespace: namespace)
  end

  def fixture(*parts)
    File.expand_path(File.join('spec/conformance', *parts), __dir__)
  end
end
