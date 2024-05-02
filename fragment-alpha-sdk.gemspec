# typed: strict
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'fragment-alpha-sdk'
  s.version = '0.1.12'
  s.email = 'snoble@fragment.dev'
  s.authors = ['fragment']
  s.files = ['lib/fragment_client.rb', 'lib/fragment_client.rbi', 'lib/fragment.schema.json', 'lib/queries.graphql']
  s.required_ruby_version = '>= 3.0'
  s.summary = 'an alpha version for the fragment client sdk'
  s.homepage = 'https://fragment.dev'
  s.license = 'Nonstandard'
  s.add_runtime_dependency 'faraday', '~> 2.6'
  s.add_runtime_dependency 'graphql-client', '~> 0.20'
  s.add_runtime_dependency 'sorbet-runtime', '~> 0.5'
end
