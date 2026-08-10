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

desc 'Typecheck with Sorbet'
task :typecheck do
  sh 'bundle exec srb tc'
end

desc 'Lint with RuboCop'
task :lint do
  sh 'bundle exec rubocop'
end

desc 'Regenerate the typed Ledger Entry payload RBI and read the diff'
task :snapshot do
  # The snapshot is the reviewable record of the surface a caller touches; see
  # test/snapshot_test.rb for why regenerating it is a decision, not a chore.
  ENV['RECORD_SNAPSHOTS'] = '1'
  ruby '-Itest test/snapshot_test.rb'
  sh 'git diff --stat -- sorbet/snapshots'
end

namespace :sorbet do
  desc 'Regenerate gem RBIs, annotations, and the unresolved-constant list'
  task :update do
    sh 'bundle exec tapioca gem --all'
    sh 'bundle exec tapioca annotations'
    sh 'bundle exec bin/tapioca todo'
  end
end

task default: %i[test typecheck]

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
