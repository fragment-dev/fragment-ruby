# typed: strict
# frozen_string_literal: true

# Static assertions about the response objects. Never loaded at runtime.
#
# The runtime objects are anonymous classes serving fields through
# `method_missing`, so these types come from the selection set and the Schema.
# graphql-client enforces the same selection set at runtime, which is what keeps
# the two in agreement.
module FragmentResponseChecks
  extend T::Sig

  sig { params(client: FragmentClient).returns(T.nilable(String)) }
  def self.scalars(client)
    ledger = client.get_ledger({ ik: 'your-ledger-ik' }).data&.ledger
    # `id` and `name` are non-null in the Schema, so they need no narrowing once
    # the nilable chain above is.
    ledger && "#{ledger.id} #{ledger.name} #{ledger.balance_utc_offset}"
  end

  sig { params(client: FragmentClient).returns(T.nilable(Integer)) }
  def self.nested(client)
    client.get_ledger_entry({ ik: 'k', ledgerIk: 'l' }).data&.ledger_entry&.lines&.nodes&.length
  end

  # A union response: every branch's fields are nilable, because graphql-client
  # returns one object whatever the `__typename`.
  sig { params(client: FragmentClient).returns(T.nilable(String)) }
  def self.union(client)
    result = client.create_ledger({ ik: 'x', ledger: { name: 'n' }, schemaKey: 'k' }).data&.create_ledger
    return nil if result.nil?

    result.__typename == 'CreateLedgerResult' ? result.ledger&.name : result.message
  end
end
