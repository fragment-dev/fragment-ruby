# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'http'
require 'graphql'
require 'json'

Rake::TestTask.new do |t|
  t.warning = false
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
end

task default: :test

namespace :graphql do
  desc 'Download and convert GraphQL schema to JSON'
  task :update_schema do
    schema_url = 'https://api.us-west-2.fragment.dev/schema.graphql'
    schema_path = 'lib/fragment.schema.json'

    response = HTTP.get(schema_url)
    schema = GraphQL::Schema.from_definition(response.to_s)
    introspection_result = GraphQL::Introspection::INTROSPECTION_QUERY
    query_result = schema.execute(introspection_result)
    json_schema = JSON.pretty_generate(query_result)

    File.open(schema_path, 'w') do |file|
      file.write(json_schema)
    end
  end
end
