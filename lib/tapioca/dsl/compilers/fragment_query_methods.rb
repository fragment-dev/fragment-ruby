# typed: strict
# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compilers)

require 'fragment_client'

module Tapioca
  module Dsl
    module Compilers
      # Declares the query and mutation methods {FragmentClient} answers to.
      #
      # `define_method_from_queries` creates one singleton method per operation on
      # each client instance, so without this Sorbet reports `Method
      # 'create_ledger' does not exist` for every one of them and a consumer has to
      # write `T.unsafe(client)`.
      #
      # Covers the operations shipped in `queries.graphql`, plus any document
      # passed to `FragmentClient.load_queries`. Operations in
      # {FragmentClient::WRAPPED_OPERATIONS} are skipped: those have hand-written
      # methods with real signatures already.
      #
      # `variables` is the operation's variables hash and stays untyped. Its keys
      # are the GraphQL variable names verbatim, as the rest of this SDK passes
      # them. The return type comes from `FragmentResponseTypes`.
      class FragmentQueryMethods < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(FragmentClient) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            [FragmentClient]
          end
        end

        sig { override.void }
        def decorate
          methods = FragmentGraphQl.operations.keys.to_h do |operation|
            [FragmentGraphQl.method_name_for(operation), operation]
          end
          methods.reject! { |name, _| FragmentClient::WRAPPED_OPERATIONS.include?(name) }
          return if methods.empty?

          root.create_path(constant) do |klass|
            methods.keys.sort.each do |name|
              klass.create_method(
                name,
                parameters: [create_param('variables', type: 'T::Hash[Symbol, T.untyped]')],
                return_type: "::FragmentClient::Responses::#{methods.fetch(name)}"
              )
            end
          end
        end
      end
    end
  end
end
