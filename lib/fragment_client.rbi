# typed: strong
# frozen_string_literal: true

# A client for Fragment
class FragmentClient
  sig { params(variables: { 'ik' => String, 'ledger' => { 'name' => String } }).returns(T::Hash[T.untyped, T.untyped]) }
  def create_ledger(variables); end

  sig do
    params(variables: { 'ledger' => { 'id' => String },
                        'ledgerAccounts' => T::Array[{ 'ik' => String, 'name' => String,
                                                       'type' => String }] }).returns(T.untyped)
  end
  def create_ledger_accounts(variables); end
end
