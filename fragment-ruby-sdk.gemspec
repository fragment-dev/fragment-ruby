# typed: strict
# frozen_string_literal: true

require_relative 'lib/fragment_client'

Gem::Specification.new do |s|
  s.name = 'fragment-ruby-sdk'
  s.version = FragmentGraphQl::VERSION
  s.email = 'snoble@fragment.dev'
  s.authors = ['fragment']
  s.files = ['lib/fragment_client.rb', 'lib/fragment_client.rbi', 'lib/fragment.schema.json', 'lib/queries.graphql']
  s.required_ruby_version = '>= 3.0'
  s.summary = 'the ruby fragment client sdk'
  s.homepage = 'https://fragment.dev'
  s.license = 'Apache-2.0'
  s.add_runtime_dependency 'graphql-client', '~> 0.20'
  s.add_runtime_dependency 'sorbet-runtime', '~> 0.5'
end
