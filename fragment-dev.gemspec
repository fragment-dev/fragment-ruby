# typed: strict
# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'fragment_client/version'

Gem::Specification.new do |s|
  s.name = 'fragment-dev'
  s.version = FragmentSDK::VERSION
  s.email = 'snoble@fragment.dev'
  s.authors = ['fragment']
  s.files = [
    'lib/fragment_client.rb',
    'lib/fragment_client.rbi',
    'lib/fragment.schema.json',
    'lib/queries.graphql',
    'lib/fragment_client/version.rb',
    'lib/fragment_client/typed_entries.rb',
    'lib/fragment_client/typed_ledger_entry.rb',
    'lib/fragment_client/graphql_ast.rb',
    # Generic; separated so it can become its own gem later.
    'lib/tapioca/dsl/helpers/graphql_sorbet_types.rb',
    # Discovered by `tapioca dsl` via `Gem.find_files`, so the path matters.
    'lib/tapioca/dsl/compilers/fragment_typed_entries.rb'
  ]
  s.required_ruby_version = '>= 3.2'
  s.summary = 'the ruby fragment client sdk'
  s.homepage = 'https://fragment.dev'
  s.license = 'Apache-2.0'
  s.add_runtime_dependency 'graphql', '>= 2.2.5', '< 3.0'
  s.add_runtime_dependency 'graphql-client', '~> 0.23.0'
  s.add_runtime_dependency 'sorbet-runtime', '~> 0.5'
end
