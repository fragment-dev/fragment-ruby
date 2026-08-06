# typed: strict
# frozen_string_literal: true

# Static assertions about the query methods. Never loaded at runtime.
#
# They are defined per instance by `define_method_from_queries`, so without the
# RBI in `sorbet/snapshots/` Sorbet reports `Method 'create_ledger' does not
# exist` for every one and a consumer has to reach for `T.unsafe`.
#
# `test/type_check_test.rb` covers the other direction.
module FragmentQueryMethodChecks
  extend T::Sig

  sig { params(client: FragmentClient).returns(T.untyped) }
  def self.queries(client)
    client.get_ledger({ ik: 'your-ledger-ik' })
    client.list_ledger_accounts({ ledgerIk: 'your-ledger-ik', first: 10 })
    client.get_ledger_account_balance({ ledgerIk: 'x', path: 'assets' })
  end

  sig { params(client: FragmentClient).returns(T.untyped) }
  def self.mutations(client)
    client.create_ledger({ ik: 'x', ledger: { name: 'n' }, schemaKey: 'k' })
    client.add_ledger_entry({ ik: 'x', ledgerIk: 'l', type: 't', parameters: {} })
  end

  # The batch wrapper is hand-written, so it keeps its own keyword signature
  # rather than the generated `variables` hash.
  sig { params(client: FragmentClient).returns(T.untyped) }
  def self.batch(client)
    client.add_ledger_entries(entries: [])
  end
end
