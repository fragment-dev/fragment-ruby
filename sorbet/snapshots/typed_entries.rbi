# DO NOT EDIT MANUALLY
# Snapshot of the RBI that `bundle exec tapioca dsl` generates for the typed
# Ledger Entry payloads `FragmentClient::TypedEntries.load` builds at load
# time. Regenerate with `bundle exec rake snapshot`.
#
# In this repository the payloads come from test/fixtures/snapshot_entries.graphql,
# a synthetic Schema shaped to exercise every branch of the derivation. The
# entry types below are not real Fragment entry types -- they exist so that
# `test/snapshot_test.rb` has a reviewable diff and `srb tc` has something to
# check. In your own application the equivalent file lands in
# `sorbet/rbi/dsl/`, generated from your Schema's operations.

# typed: true

class FragmentClient::Entries::AuthCaptureV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, user_id: ::String, capture_amount: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, user_id:, capture_amount:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `user_id` (`String!`).
  sig { returns(::String) }
  def user_id; end

  # Schema parameter `capture_amount` (`Int96!`).
  sig { returns(::String) }
  def capture_amount; end

  # "auth_capture"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::Entry2faChallengeV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # "2fa_challenge"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::ReservedV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, type: ::String, class_: ::String, posted_: ::String, userId: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, type:, class_:, posted_:, userId:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `type` (`String!`).
  sig { returns(::String) }
  def type; end

  # Schema parameter `class` (`String!`). Exposed as `class_` because `class` is already taken; the wire name is unchanged.
  sig { returns(::String) }
  def class_; end

  # Schema parameter `posted` (`String!`). Exposed as `posted_` because `posted` is already taken; the wire name is unchanged.
  sig { returns(::String) }
  def posted_; end

  # Schema parameter `userId` (`String!`).
  sig { returns(::String) }
  def userId; end

  # "reserved"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::UserFundsAccountV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, amount: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, amount:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `amount` (`Int96!`).
  sig { returns(::String) }
  def amount; end

  # "user-funds-account"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::UserFundsAccountV2 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, amount: ::String, isExternal: T::Boolean, tagKeys: T::Array[::String], mode: T.untyped, feeAmount: T.nilable(::String), settledAt: T.nilable(::String), retryCount: T.nilable(::Integer), noteLines: T.nilable(T::Array[T.nilable(::String)]), channel: T.untyped, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, amount:, isExternal:, tagKeys:, mode:, feeAmount: T.unsafe(nil), settledAt: T.unsafe(nil), retryCount: T.unsafe(nil), noteLines: T.unsafe(nil), channel: T.unsafe(nil), posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `amount` (`Int96!`).
  sig { returns(::String) }
  def amount; end

  # Schema parameter `feeAmount` (`Int96`).
  sig { returns(T.nilable(::String)) }
  def feeAmount; end

  # Schema parameter `settledAt` (`DateTime`).
  sig { returns(T.nilable(::String)) }
  def settledAt; end

  # Schema parameter `isExternal` (`Boolean!`).
  sig { returns(T::Boolean) }
  def isExternal; end

  # Schema parameter `retryCount` (`Int`).
  sig { returns(T.nilable(::Integer)) }
  def retryCount; end

  # Schema parameter `tagKeys` (`[SafeString!]!`).
  sig { returns(T::Array[::String]) }
  def tagKeys; end

  # Schema parameter `noteLines` (`[String]`).
  sig { returns(T.nilable(T::Array[T.nilable(::String)])) }
  def noteLines; end

  # Schema parameter `mode` (`TransferMode!`).
  sig { returns(T.untyped) }
  def mode; end

  # Schema parameter `channel` (`TransferChannel`).
  sig { returns(T.untyped) }
  def channel; end

  # "user-funds-account"
  sig { returns(::String) }
  def self.entry_type; end

  # 2
  sig { returns(::Integer) }
  def self.type_version; end
end
