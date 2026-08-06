# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'minitest/autorun'
require 'tapioca/internal'
require 'tapioca/dsl/compilers/fragment_response_types'

# The response-type compiler, tested directly rather than only through the
# snapshot -- a snapshot records whatever the compiler emits, so on its own it
# cannot tell a correct signature from a wrong one that has been recorded.
class ResponseTypesTest < Minitest::Test
  COMPILER = Tapioca::Dsl::Compilers::FragmentResponseTypes

  def setup
    FragmentGraphQl.reset_operations!
  end

  def teardown
    FragmentGraphQl.reset_operations!
  end

  # --- Types derived from the Schema ----------------------------------------

  def test_non_null_scalars_are_not_nilable_and_nullable_ones_are
    rbi = generate(<<~GQL)
      query Scalars { ledger(ledger: { ik: "x" }) { id name balanceUTCOffset } }
    GQL

    # id: ID!, name: String!, balanceUTCOffset: UTCOffset! -- all non-null.
    assert_signature rbi, 'id', '::String'
    assert_signature rbi, 'name', '::String'
    assert_signature rbi, 'balance_utc_offset', '::String'
    # `ledger` itself is nullable in the Schema.
    assert_signature rbi, 'ledger', 'T.nilable(Ledger)'
  end

  def test_lists_carry_their_element_nullability
    # `nodes` on a connection is `[LedgerLine!]!`, so neither the array nor its
    # elements are nilable.
    rbi = generate(<<~GQL)
      query Listy {
        ledgerEntry(ledgerEntry: { ik: "x", ledger: { ik: "y" } }) {
          lines { nodes { id amount } }
        }
      }
    GQL

    assert_match(/sig { returns\(T::Array\[Nodes\]\) }\s+def nodes; end/, rbi)
  end

  def test_a_scalar_absent_from_the_table_is_untyped_not_guessed
    rbi = generate(<<~GQL)
      query Untypeable { workspace { id name } }
    GQL

    # Whatever `id` is, it must not have been invented; ID! maps to ::String.
    assert_signature rbi, 'id', '::String'
  end

  # --- Selection-set shape --------------------------------------------------

  def test_an_alias_names_the_method_and_the_nested_class
    rbi = generate(<<~GQL)
      query Aliased {
        ledger(ledger: { ik: "x" }) { entrySchema: schema { key } }
      }
    GQL

    assert_match(/def entry_schema; end/, rbi)
    assert_match(/class EntrySchema/, rbi)
    refute_match(/def schema; end/, rbi)
  end

  def test_typename_is_a_string
    rbi = generate(<<~GQL)
      query Typed { ledger(ledger: { ik: "x" }) { __typename id } }
    GQL

    assert_match(/sig { returns\(::String\) }\s+def __typename; end/, rbi)
  end

  def test_a_deeply_nested_selection_nests_a_class_per_level
    rbi = generate(<<~GQL)
      query Deep {
        ledgerEntry(ledgerEntry: { ik: "x", ledger: { ik: "y" } }) {
          lines { nodes { account { path } } }
        }
      }
    GQL

    %w[LedgerEntry Lines Nodes Account].each do |level|
      assert_match(/class #{level}/, rbi, "missing nested class #{level}")
    end
    assert_match(/def path; end/, rbi)
  end

  # --- Unions ---------------------------------------------------------------

  def test_a_union_contributes_every_branch_and_makes_it_nilable
    rbi = generate(<<~GQL)
      mutation Unioned($ik: SafeString!) {
        createLedger(ik: $ik, ledger: { name: "n" }, schema: { key: "k" }) {
          __typename
          ... on CreateLedgerResult { isIkReplay }
          ... on BadRequestError { code message retryable }
        }
      }
    GQL

    # One object whatever the __typename, so every branch's fields are nilable.
    assert_signature rbi, 'is_ik_replay', 'T.nilable(T::Boolean)'
    assert_signature rbi, 'message', 'T.nilable(::String)'
    assert_signature rbi, 'retryable', 'T.nilable(T::Boolean)'
    assert_signature rbi, '__typename', '::String'
  end

  def test_a_field_selected_in_two_branches_is_declared_once
    rbi = generate(<<~GQL)
      mutation Overlap($ik: SafeString!) {
        createLedger(ik: $ik, ledger: { name: "n" }, schema: { key: "k" }) {
          ... on BadRequestError { code }
          ... on InternalError { code }
        }
      }
    GQL

    assert_equal 1, rbi.scan(/def code; end/).length, 'code declared more than once'
  end

  private

  # Only the operation under test, so an assertion cannot be satisfied by some
  # other operation in `queries.graphql` that happens to select the same field.
  def generate(source)
    FragmentGraphQl.operations.clear
    FragmentGraphQl.record_document(source)
    COMPILER.reset_state
    Tapioca::Dsl::Pipeline.new(
      requested_constants: [FragmentClient], requested_compilers: [COMPILER], number_of_workers: 1
    ).run { |_constant, rbi| rbi.string }.join
  end

  def assert_signature(rbi, method, type)
    found = rbi[/sig { returns\((.+?)\) }\s+def #{Regexp.escape(method)}; end/, 1]
    assert_equal type, found, "signature for #{method}"
  end
end
