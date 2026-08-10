# typed: strict
# frozen_string_literal: true

require 'graphql'
require 'sorbet-runtime'

class FragmentClient
  # Reading helpers for graphql-ruby's language AST.
  #
  # Nothing here knows about Fragment. Kept separate so it can move to a gem of
  # its own if a second consumer appears -- no such gem exists today.
  #
  # Named `GraphqlAst` rather than `GraphQL::Ast`: a `FragmentClient::GraphQL`
  # would shadow the real `GraphQL` for every constant lookup inside
  # {FragmentClient}.
  module GraphqlAst
    extend T::Sig

    class << self
      extend T::Sig

      # The operation's only root field, if it is a field with that name.
      #
      # `nil` for the wrong operation type, more than one selection, or a
      # selection that is a fragment spread rather than a field.
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition,
               field_name: String, operation_type: String)
          .returns(T.nilable(GraphQL::Language::Nodes::Field))
      end
      def single_root_field(operation, field_name, operation_type: 'mutation')
        return nil unless operation.operation_type == operation_type

        selections = operation.selections
        return nil unless selections.length == 1

        root = selections.first
        return nil unless root.is_a?(GraphQL::Language::Nodes::Field)

        root.name == field_name ? root : nil
      end

      # An argument's value when it is written as an inline object literal, as
      # opposed to passed as a variable or absent.
      sig do
        params(field: GraphQL::Language::Nodes::Field, argument_name: String)
          .returns(T.nilable(GraphQL::Language::Nodes::InputObject))
      end
      def inline_object_argument(field, argument_name)
        value = field.arguments.find { |argument| argument.name == argument_name }&.value
        value.is_a?(GraphQL::Language::Nodes::InputObject) ? value : nil
      end

      # One field of an inline object literal, or `nil` if absent. A field written
      # as `null` yields a `NullValue` node, not `nil`.
      sig do
        params(object: GraphQL::Language::Nodes::InputObject, name: String).returns(T.untyped)
      end
      def object_field(object, name)
        object.arguments.find { |argument| argument.name == name }&.value
      end

      # Variable name to declared type node.
      sig do
        params(operation: GraphQL::Language::Nodes::OperationDefinition)
          .returns(T::Hash[String, T.untyped])
      end
      def variable_types(operation)
        operation.variables.to_h { |definition| [definition.name, definition.type] }
      end
    end
  end
end
