# typed: strict
# frozen_string_literal: true

# Static assertions about the typed Ledger Entry payloads. Never loaded at
# runtime; `srb tc` is the whole point of the file.
#
# The payload classes are built at load time, so nothing about their signatures is
# visible to Sorbet without the RBI in `sorbet/snapshots/typed_entries.rbi`. This
# is what proves that RBI is more than a file on disk: if the Tapioca compiler
# emitted a signature Sorbet rejects, or the wrong type for a parameter, this
# fails to typecheck.
#
# The payloads here come from `test/fixtures/snapshot_entries.graphql` and are
# synthetic. `test/type_check_test.rb` covers the other direction -- that wrong
# calls are actually *rejected* -- because Sorbet has no way to assert an expected
# error inline.
module FragmentTypeChecks
  extend T::Sig

  # Required parameters are required, and typed from the operation's variables.
  sig { returns(FragmentClient::Entries::AuthCaptureV1) }
  def self.minimal
    FragmentClient::Entries::AuthCaptureV1.new(
      ik: 'ik-1', ledger_ik: 'prod', user_id: 'user-1', capture_amount: '100'
    )
  end

  # Every optional common field is accepted, and so is an explicit nil. The two
  # stay distinguishable on the wire (spec 3.2) without the caller ever seeing a
  # sentinel: `#set?` is what reports the difference.
  sig { returns(FragmentClient::Entries::AuthCaptureV1) }
  def self.with_common_fields
    FragmentClient::Entries::AuthCaptureV1.new(
      ik: 'ik-1', ledger_ik: 'prod', user_id: 'user-1', capture_amount: '100',
      posted: '2026-01-01T00:00:00Z', description: nil,
      tags: [{ key: 'k', value: 'v' }], groups: [], conditions: []
    )
  end

  # Non-String scalars keep their Ruby types: `Int` is an Integer, `Boolean` a
  # boolean, `[SafeString!]!` an array of strings, and an unmapped enum lands on
  # `T.untyped` rather than being guessed at.
  sig { returns(FragmentClient::Entries::UserFundsAccountV2) }
  def self.scalar_types
    FragmentClient::Entries::UserFundsAccountV2.new(
      ik: 'ik-2', ledger_ik: 'prod', amount: '100', isExternal: true,
      tagKeys: %w[a b], mode: :transfer, retryCount: 3, noteLines: ['first', nil]
    )
  end

  # A parameter whose Schema name is unusable as a method name is reachable under
  # its escaped name (spec 2.5).
  sig { returns(String) }
  def self.escaped_names
    entry = FragmentClient::Entries::ReservedV1.new(
      ik: 'r-1', ledger_ik: 'prod', type: 't', class_: 'c', posted_: 'p', userId: 'u'
    )
    entry.class_ + entry.posted_ + entry.type + entry.userId
  end

  # A required parameter's reader is not nilable, so it needs no narrowing.
  sig { returns(Integer) }
  def self.required_reader_needs_no_narrowing
    minimal.user_id.length
  end

  # An optional one's does, and the sentinel is part of what has to be narrowed.
  sig { returns(T.nilable(Integer)) }
  def self.optional_reader_must_be_narrowed
    fee = scalar_types.feeAmount
    fee.is_a?(String) ? fee.length : nil
  end

  # The derived facts are readable off the class.
  sig { returns([String, Integer]) }
  def self.identity
    [FragmentClient::Entries::UserFundsAccountV2.entry_type,
     FragmentClient::Entries::UserFundsAccountV2.type_version]
  end

  # A batch takes typed payloads and raw hashes together (spec 3.5).
  sig { params(client: FragmentClient).returns(T.untyped) }
  def self.batch(client)
    client.add_ledger_entries(
      entries: [minimal, { ik: 'raw', entry: { ledger: { ik: 'prod' }, type: 'other' } }]
    )
  end

  # `to_entry_input` is a plain hash, so a caller can inspect or adjust a payload
  # before sending it.
  sig { returns(T::Hash[String, T.untyped]) }
  def self.wire_payload
    minimal.to_entry_input
  end
end
