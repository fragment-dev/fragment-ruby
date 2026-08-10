# typed: strict
# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compilers)

require 'fragment_client'
require 'tapioca/dsl/helpers/graphql_sorbet_types'

module Tapioca
  module Dsl
    module Compilers
      # Declares the response objects the query methods return, so that
      # `client.get_ledger(...).data.ledger.name` typechecks.
      #
      # graphql-client builds those objects at runtime from anonymous classes whose
      # fields are served by `method_missing`, so there is nothing to reflect on.
      # The shape is instead derived statically from each operation's selection set
      # and the pinned Schema -- the same two inputs graphql-client itself uses,
      # which is what makes the declared types agree with the runtime.
      #
      # In particular graphql-client refuses at runtime to read a field the
      # operation did not select (`ImplicitlyFetchedFieldError`), so a type derived
      # from the selection set cannot promise more than the runtime allows.
      #
      # Emitted under `FragmentClient::Responses::<Operation>`, one nested class per
      # selection level.
      class FragmentResponseTypes < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(FragmentClient) } }

        # Scalar names this Schema uses, mapped for `GraphqlSorbetTypes`.
        SCALARS = T.let(
          {
            'String' => '::String', 'ID' => '::String', 'SafeString' => '::String',
            'ParameterizedString' => '::String', 'Date' => '::String',
            'DateTime' => '::String', 'FirstMoment' => '::String',
            'LastMoment' => '::String', 'Period' => '::String',
            'PeriodFilter' => '::String', 'UTCOffset' => '::String',
            'Int96' => '::String', 'Int' => '::Integer', 'Float' => '::Float',
            'Boolean' => 'T::Boolean', 'JSON' => 'T.untyped', 'Parameters' => 'T.untyped'
          }.freeze,
          T::Hash[String, String]
        )

        RESPONSES_NAMESPACE = 'FragmentClient::Responses'

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            [FragmentClient]
          end
        end

        sig { override.void }
        def decorate
          operations = FragmentGraphQl.operations
          return if operations.empty?

          root.create_module(RESPONSES_NAMESPACE) do |namespace|
            operations.keys.sort.each do |name|
              declare_operation(namespace, name, T.must(operations[name]))
            end
          end
        end

        private

        sig do
          params(namespace: RBI::Scope, name: String,
                 operation: GraphQL::Language::Nodes::OperationDefinition).void
        end
        def declare_operation(namespace, name, operation)
          root_type = operation.operation_type == 'mutation' ? schema.mutation : schema.query
          return if root_type.nil?

          namespace.create_class(name) do |response|
            response.create_method('data', return_type: "T.nilable(#{RESPONSES_NAMESPACE}::#{name}::Data)")
            response.create_method('errors', return_type: 'T.untyped')
            response.create_method('original_hash', return_type: 'T::Hash[String, T.untyped]')
            declare_object(response, 'Data', operation.selections, root_type)
          end
        end

        # One nested class per selection level. `path` is its fully qualified name,
        # which children extend so nested references resolve.
        sig do
          params(parent: RBI::Scope, class_name: String, selections: T::Array[T.untyped],
                 graphql_type: T.untyped).void
        end
        def declare_object(parent, class_name, selections, graphql_type)
          fields = collect_fields(selections, graphql_type)

          parent.create_class(class_name) do |scope|
            fields.each do |field|
              scope.create_method(field.fetch(:method), return_type: field.fetch(:type),
                                                        comments: field.fetch(:comments))
              nested = field[:nested]
              next unless nested

              declare_object(scope, nested.fetch(:class_name), nested.fetch(:selections),
                             nested.fetch(:type))
            end
          end
        end

        # Flatten a selection set into field descriptors, following inline fragments.
        #
        # A union or interface selection contributes every branch's fields, each
        # made nilable: graphql-client returns one object whatever the `__typename`,
        # and only the branch that matched carries values.
        sig do
          params(selections: T::Array[T.untyped], graphql_type: T.untyped, force_nilable: T::Boolean,
                 taken: T::Set[String])
            .returns(T::Array[T::Hash[Symbol, T.untyped]])
        end
        def collect_fields(selections, graphql_type, force_nilable: false, taken: Set.new)
          selections.flat_map do |selection|
            case selection
            when GraphQL::Language::Nodes::Field
              field = describe_field(selection, graphql_type, force_nilable, taken)
              field ? [field] : []
            when GraphQL::Language::Nodes::InlineFragment
              branch = selection.type ? lookup_type(selection.type.name) : graphql_type
              next [] if branch.nil?

              collect_fields(selection.selections, branch, force_nilable: true, taken: taken)
            else
              []
            end
          end
        end

        sig do
          params(selection: GraphQL::Language::Nodes::Field, graphql_type: T.untyped,
                 force_nilable: T::Boolean, taken: T::Set[String])
            .returns(T.nilable(T::Hash[Symbol, T.untyped]))
        end
        def describe_field(selection, graphql_type, force_nilable, taken)
          name = selection.alias || selection.name
          method = ActiveSupport::Inflector.underscore(name)
          return nil if taken.include?(method)

          taken << method
          return { method: method, type: '::String', comments: [], nested: nil } if name == '__typename'

          field = graphql_type.respond_to?(:fields) ? graphql_type.fields[selection.name] : nil
          return { method: method, type: 'T.untyped', comments: [], nested: nil } if field.nil?

          build_field(selection, field, method, name, force_nilable, taken)
        end

        sig do
          params(selection: GraphQL::Language::Nodes::Field, field: T.untyped, method: String,
                 name: String, force_nilable: T::Boolean, taken: T::Set[String])
            .returns(T::Hash[Symbol, T.untyped])
        end
        def build_field(selection, field, method, name, force_nilable, taken)
          unwrapped = field.type.unwrap
          nilable = force_nilable || !field.type.non_null?

          if selection.selections.empty?
            return { method: method, type: wrap(scalar_type(unwrapped), field.type, nilable),
                     comments: [comment("`#{name}`: #{field.type.to_type_signature}")], nested: nil }
          end

          class_name = ActiveSupport::Inflector.camelize(method)
          class_name = "#{class_name}Object" if taken.include?("class:#{class_name}")
          taken << "class:#{class_name}"

          { method: method, type: wrap(class_name, field.type, nilable),
            comments: [comment("`#{name}`: #{field.type.to_type_signature}")],
            nested: { class_name: class_name, selections: selection.selections,
                      type: unwrapped } }
        end

        # Apply the GraphQL type's list and nullability wrappers to `inner`.
        #
        # `[Ledger!]!` becomes `T::Array[X]`, `[Ledger]` becomes
        # `T::Array[T.nilable(X)]`. `T.untyped` already includes nil, so it is never
        # wrapped again.
        sig { params(inner: String, graphql_type: T.untyped, nilable: T::Boolean).returns(String) }
        def wrap(inner, graphql_type, nilable)
          bare = graphql_type.non_null? ? graphql_type.of_type : graphql_type
          type = if bare.list?
                   "T::Array[#{nilable_unless(inner, bare.of_type.non_null?)}]"
                 else
                   inner
                 end
          nilable_unless(type, !nilable)
        end

        sig { params(type: String, non_null: T::Boolean).returns(String) }
        def nilable_unless(type, non_null)
          non_null || type == 'T.untyped' ? type : "T.nilable(#{type})"
        end

        sig { params(unwrapped: T.untyped).returns(String) }
        def scalar_type(unwrapped)
          Helpers::GraphqlSorbetTypes.translate(unwrapped.graphql_name, scalars: SCALARS)
        end

        sig { params(name: String).returns(T.untyped) }
        def lookup_type(name)
          schema.types[name]
        end

        sig { returns(T.untyped) }
        def schema
          FragmentGraphQl::FragmentSchema
        end

        sig { params(text: String).returns(RBI::Comment) }
        def comment(text)
          RBI::Comment.new(text)
        end
      end
    end
  end
end
