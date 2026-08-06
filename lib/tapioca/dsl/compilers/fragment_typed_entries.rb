# typed: strict
# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compilers)

require 'fragment_client'
require 'tapioca/dsl/helpers/graphql_sorbet_types'

module Tapioca
  module Dsl
    module Compilers
      # Declares the typed payload classes {FragmentClient::TypedEntries.load}
      # builds at load time, giving each a real `initialize` signature and typed
      # readers.
      #
      # `bundle exec tapioca dsl` writes them to
      # `sorbet/rbi/dsl/fragment_client/entries/`. The classes are only visible if
      # whatever calls `TypedEntries.load` runs when Tapioca loads the application;
      # it needs no credentials, so an initializer works.
      class FragmentTypedEntries < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(FragmentClient::TypedLedgerEntry) } }

        # Sorbet types for the scalars a Fragment Schema binds parameters to.
        # Anything absent -- enums, input objects, newer scalars -- falls through to
        # `T.untyped` rather than a guess that could reject a valid call.
        GRAPHQL_SCALARS = T.let(
          {
            'String' => '::String',
            'ID' => '::String',
            'SafeString' => '::String',
            'ParameterizedString' => '::String',
            # ISO 8601 strings, not Ruby date objects.
            'Date' => '::String',
            'DateTime' => '::String',
            'FirstMoment' => '::String',
            'LastMoment' => '::String',
            'Period' => '::String',
            'PeriodFilter' => '::String',
            'UTCOffset' => '::String',
            # Fragment's big integers are strings on the wire.
            'Int96' => '::String',
            'Int' => '::Integer',
            'Float' => '::Float',
            'Boolean' => 'T::Boolean',
            'JSON' => 'T.untyped',
            'Parameters' => 'T.untyped'
          }.freeze,
          T::Hash[String, String]
        )

        # The optional common fields, in the order the base class declares them.
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
            # `name_of` is nil for a payload in an anonymous namespace, whose name
            # (`#<Module:0x...>::AuthCaptureV1`) Sorbet cannot resolve anyway.
            descendants_of(FragmentClient::TypedLedgerEntry).select { |klass| name_of(klass) }
          end
        end

        sig { override.void }
        def decorate
          spec = constant.spec

          # `create_path` would omit the superclass, leaving Sorbet unaware that a
          # payload inherits `to_entry_input`, `set?` and the common-field readers.
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

          # Required before optional: Sorbet rejects a `sig` that interleaves them,
          # though Ruby permits it for keyword arguments. Source order survives
          # within each group and on the wire, which is where spec 2.4 applies.
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

        # Optional fields are plainly nilable: the unset sentinel is private to the
        # constructor and never reaches a caller.
        sig { params(type: String).returns(String) }
        def nilable(type)
          type == 'T.untyped' ? 'T.untyped' : "T.nilable(#{type})"
        end

        sig { params(parameter: FragmentClient::TypedEntries::Parameter).returns(String) }
        def sorbet_type(parameter)
          Helpers::GraphqlSorbetTypes.translate(parameter.graphql_type, scalars: GRAPHQL_SCALARS)
        end

        sig { params(parameter: FragmentClient::TypedEntries::Parameter).returns(T::Array[RBI::Comment]) }
        def parameter_comments(parameter)
          text = "Schema parameter `#{parameter.wire_name}` (`#{parameter.graphql_type}`)."
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
