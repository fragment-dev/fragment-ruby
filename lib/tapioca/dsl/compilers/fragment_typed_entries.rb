# typed: strict
# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compilers)

require 'fragment_client'

module Tapioca
  module Dsl
    module Compilers
      # Teaches Sorbet about the typed `addLedgerEntries` payload classes that
      # {FragmentClient::TypedEntries.load} builds at load time.
      #
      # The payloads are derived from a Schema's `.graphql` operations rather than
      # generated to disk, because that is how Ruby libraries normally do this --
      # but it also means Sorbet cannot see them. This compiler closes that gap
      # the same way Tapioca's ActiveRecord compilers do for dynamically defined
      # attributes: run `bundle exec tapioca dsl` and each payload gets a real
      # `initialize` signature and typed readers.
      #
      #     # sorbet/rbi/dsl/fragment_client/entries/auth_capture_v1.rbi
      #     class FragmentClient::Entries::AuthCaptureV1
      #       sig do
      #         params(ik: ::String, ledger_ik: ::String, user_id: ::String,
      #                capture_amount: ::String, ...).void
      #       end
      #       def initialize(ik:, ledger_ik:, user_id:, capture_amount:, ...); end
      #     end
      #
      # For the classes to be visible, whatever calls `TypedEntries.load` has to
      # run when Tapioca loads the application. `load` needs no credentials and
      # makes no network calls precisely so it can sit in an initializer.
      class FragmentTypedEntries < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(FragmentClient::TypedLedgerEntry) } }

        # Sorbet types for the scalars a Fragment Schema binds parameters to.
        #
        # Anything absent falls through to `T.untyped`: enums, input objects and
        # scalars added to the Schema after this table was written. Guessing wrong
        # would reject a call that the API accepts, which is worse than not
        # checking it.
        GRAPHQL_SCALARS = T.let(
          {
            'String' => '::String',
            'ID' => '::String',
            'SafeString' => '::String',
            'ParameterizedString' => '::String',
            # Serialized as ISO 8601 strings, not as Ruby date objects.
            'Date' => '::String',
            'DateTime' => '::String',
            'FirstMoment' => '::String',
            'LastMoment' => '::String',
            'Period' => '::String',
            'PeriodFilter' => '::String',
            'UTCOffset' => '::String',
            # Fragment binds its big integers to strings, which is also why the
            # spec's strict profile can forbid float-typed parameters outright.
            'Int96' => '::String',
            'Int' => '::Integer',
            'Float' => '::Float',
            'Boolean' => 'T::Boolean',
            'JSON' => 'T.untyped',
            'Parameters' => 'T.untyped'
          }.freeze,
          T::Hash[String, String]
        )

        # The optional common fields every payload carries, and their types.
        # Ordered as they are declared on the base class.
        COMMON_OPTIONAL_FIELDS = T.let(
          {
            posted: '::String',
            description: '::String',
            tags: 'T::Array[T.untyped]',
            groups: 'T::Array[T.untyped]',
            conditions: 'T::Array[T.untyped]'
          }.freeze,
          T::Hash[Symbol, String]
        )

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            # A payload loaded into an anonymous namespace has a name Sorbet
            # cannot resolve (`#<Module:0x...>::AuthCaptureV1`), so there is
            # nothing to attach an RBI to. `name_of` is Tapioca's own test for
            # that, and returns nil for exactly those.
            descendants_of(FragmentClient::TypedLedgerEntry).select { |klass| name_of(klass) }
          end
        end

        sig { override.void }
        def decorate
          spec = constant.spec

          # `create_path` would declare the class with no superclass, and Sorbet
          # would then not know a payload inherits `to_entry_input`, `set?` or the
          # common-field readers.
          root.create_class(constant.to_s,
                            superclass_name: '::FragmentClient::TypedLedgerEntry') do |payload|
            payload.create_method('initialize', parameters: initialize_parameters(spec),
                                                return_type: 'void')

            spec.parameters.each do |parameter|
              payload.create_method(parameter.name.to_s, return_type: reader_type(parameter),
                                                         comments: parameter_comments(parameter))
            end

            payload.create_method('entry_type', return_type: '::String', class_method: true,
                                                comments: [comment(spec.entry_type.inspect)])
            payload.create_method('type_version', return_type: '::Integer', class_method: true,
                                                  comments: [comment(spec.type_version.to_s)])
          end
        end

        private

        sig do
          params(spec: FragmentClient::TypedEntries::EntrySpec)
            .returns(T::Array[RBI::TypedParam])
        end
        def initialize_parameters(spec)
          required, optional = spec.parameters.partition(&:required)

          # Required parameters before optional ones, because Sorbet rejects a
          # `sig` that interleaves them ("Malformed `sig`. Required parameter ...
          # must be declared before all the optional ones"), even for keyword
          # arguments where Ruby itself permits any order.
          #
          # Reordering a signature is accepted as long as parameters are supplied
          # by name, which is what spec 2.6 depends on -- and these are keyword
          # arguments, so declaration order is invisible to a caller. Source order
          # is preserved within each group, and on the wire, which is where spec
          # 2.4 is observable.
          parameters = [
            create_kw_param('ik', type: '::String'),
            create_kw_param('ledger_ik', type: '::String')
          ]
          required.each do |parameter|
            parameters << create_kw_param(parameter.name.to_s, type: sorbet_type(parameter))
          end
          optional.each do |parameter|
            parameters << create_kw_opt_param(parameter.name.to_s, type: optional_type(parameter),
                                                                   default: 'T.unsafe(nil)')
          end
          COMMON_OPTIONAL_FIELDS.each do |name, type|
            parameters << create_kw_opt_param(name.to_s, type: nilable(type),
                                                         default: 'T.unsafe(nil)')
          end

          parameters
        end

        sig { params(parameter: FragmentClient::TypedEntries::Parameter).returns(String) }
        def reader_type(parameter)
          parameter.required ? sorbet_type(parameter) : optional_type(parameter)
        end

        sig { params(parameter: FragmentClient::TypedEntries::Parameter).returns(String) }
        def optional_type(parameter)
          nilable(sorbet_type(parameter))
        end

        # An optional field is nilable and nothing more exotic. The unset sentinel
        # never reaches a caller -- it is the constructor's private marker for an
        # omitted keyword -- so putting it in the signature would only make every
        # optional field harder to read and to narrow.
        sig { params(type: String).returns(String) }
        def nilable(type)
          type == 'T.untyped' ? 'T.untyped' : "T.nilable(#{type})"
        end

        # Translate the GraphQL type of the bound variable, as written in the
        # operation, into a Sorbet type.
        #
        # Top-level nullability is the caller's business, since it also has to
        # fold in the unset sentinel. Nullability *inside* a list is folded in
        # here, because nothing else can express it.
        sig { params(parameter: FragmentClient::TypedEntries::Parameter).returns(String) }
        def sorbet_type(parameter)
          graphql_type_to_sorbet(parameter.graphql_type)
        end

        sig { params(graphql_type: String).returns(String) }
        def graphql_type_to_sorbet(graphql_type)
          type = graphql_type.delete_suffix('!')
          return GRAPHQL_SCALARS.fetch(type, 'T.untyped') unless type.start_with?('[')

          "T::Array[#{list_element_type(type.delete_prefix('[').delete_suffix(']'))}]"
        end

        sig { params(element: String).returns(String) }
        def list_element_type(element)
          type = graphql_type_to_sorbet(element)
          return type if element.end_with?('!') || type == 'T.untyped'

          "T.nilable(#{type})"
        end

        sig { params(parameter: FragmentClient::TypedEntries::Parameter).returns(T::Array[RBI::Comment]) }
        def parameter_comments(parameter)
          text = "Schema parameter `#{parameter.wire_name}` (`#{parameter.graphql_type}`)."
          # Worth naming: the caller is using an identifier they did not choose,
          # and it is not the one the API sees.
          if parameter.escaped?
            text += " Exposed as `#{parameter.name}` because `#{parameter.wire_name}` is " \
                    'already taken; the wire name is unchanged.'
          end
          [comment(text)]
        end

        sig { params(text: String).returns(RBI::Comment) }
        def comment(text)
          RBI::Comment.new(text)
        end
      end
    end
  end
end
