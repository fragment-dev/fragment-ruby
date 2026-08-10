# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      # Translates a GraphQL type expression, as written in a document, into a
      # Sorbet type string.
      #
      # Nothing here knows about Fragment: the scalar table is supplied by the
      # caller, and anything absent from it becomes `T.untyped`. Kept separate so
      # it can move to a gem of its own if a second consumer appears -- no gem
      # does this today, and Tapioca ships no GraphQL compiler.
      #
      #     translate('[SafeString!]!', scalars: { 'SafeString' => '::String' })
      #     #=> "T::Array[::String]"
      #     translate('[String]', scalars: { 'String' => '::String' })
      #     #=> "T::Array[T.nilable(::String)]"
      #
      # Top-level nullability is the caller's to apply, since only the caller knows
      # whether an optional field is nilable, defaulted, or something else.
      # Nullability inside a list is applied here, having nowhere else to go.
      module GraphqlSorbetTypes
        extend T::Sig

        UNTYPED = 'T.untyped'

        class << self
          extend T::Sig

          sig { params(graphql_type: String, scalars: T::Hash[String, String]).returns(String) }
          def translate(graphql_type, scalars:)
            type = graphql_type.delete_suffix('!')
            return scalars.fetch(type, UNTYPED) unless type.start_with?('[')

            element = type.delete_prefix('[').delete_suffix(']')
            "T::Array[#{list_element(element, scalars: scalars)}]"
          end

          private

          sig { params(element: String, scalars: T::Hash[String, String]).returns(String) }
          def list_element(element, scalars:)
            type = translate(element, scalars: scalars)
            return type if element.end_with?('!') || type == UNTYPED

            "T.nilable(#{type})"
          end
        end
      end
    end
  end
end
