# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'minitest/autorun'
require 'tapioca/internal'
require 'tapioca/dsl/helpers/graphql_sorbet_types'

# Direct tests for the generic type translation, which knows nothing about
# Fragment and is separated so it can be lifted into its own gem.
class GraphqlSorbetTypesTest < Minitest::Test
  SCALARS = { 'String' => '::String', 'Int' => '::Integer', 'Boolean' => 'T::Boolean',
              'JSON' => 'T.untyped' }.freeze

  CASES = {
    'String' => '::String',
    'String!' => '::String',
    'Int!' => '::Integer',
    'Boolean' => 'T::Boolean',
    # Absent from the table: an enum, an input object, a scalar added later.
    'TransferMode!' => 'T.untyped',
    'JSON' => 'T.untyped',
    # Non-null elements stay non-nilable; nullable ones do not.
    '[String!]!' => 'T::Array[::String]',
    '[String!]' => 'T::Array[::String]',
    '[String]' => 'T::Array[T.nilable(::String)]',
    '[String]!' => 'T::Array[T.nilable(::String)]',
    '[Int]' => 'T::Array[T.nilable(::Integer)]',
    # An unmapped element is already `T.untyped`, which includes nil.
    '[TransferMode]' => 'T::Array[T.untyped]',
    '[[String!]!]!' => 'T::Array[T::Array[::String]]'
  }.freeze

  def test_translates_every_shape
    CASES.each do |graphql, sorbet|
      assert_equal sorbet,
                   Tapioca::Dsl::Helpers::GraphqlSorbetTypes.translate(graphql, scalars: SCALARS),
                   "#{graphql} translated wrongly"
    end
  end

  def test_the_scalar_table_is_the_callers
    assert_equal 'MyString',
                 Tapioca::Dsl::Helpers::GraphqlSorbetTypes.translate(
                   'String!', scalars: { 'String' => 'MyString' }
                 )
    assert_equal 'T.untyped',
                 Tapioca::Dsl::Helpers::GraphqlSorbetTypes.translate('String!', scalars: {})
  end
end
