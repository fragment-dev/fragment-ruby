# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'minitest/autorun'
require 'json'
require 'logger'
require 'webmock/minitest'

# That the generated response types agree with what graphql-client actually serves.
#
# The types are derived from each operation's selection set; graphql-client derives
# its runtime objects from the same selection set and refuses any field outside it
# (`ImplicitlyFetchedFieldError`). This asserts that correspondence instead of
# assuming it -- the snapshot cannot, because it records whatever the compiler
# emitted, and `srb tc` cannot, because it never runs the client.
#
# Reading the method names out of the generated RBI rather than re-deriving them
# keeps the two sides independent: the RBI is the input here, not the expectation.
class ResponseAgreementTest < Minitest::Test
  include WebMock::API

  SNAPSHOT = File.expand_path('../sorbet/snapshots/typed_entries.rbi', __dir__)

  # One operation per shape worth checking.
  OPERATIONS = {
    'GetLedger' => :get_ledger,
    'GetLedgerEntry' => :get_ledger_entry,
    'ListLedgerAccounts' => :list_ledger_accounts,
    'GetWorkspace' => :get_workspace
  }.freeze

  def setup
    FragmentClient.instance_variable_set(:@configuration, nil)
    FragmentClient.configure { |config| config.logger = Logger.new(File::NULL) }
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 't', expires_in: 3600 }.to_json)
  end

  def teardown
    FragmentClient.instance_variable_set(:@configuration, nil)
  end

  def test_every_declared_method_is_one_the_runtime_serves
    checked = 0
    OPERATIONS.each do |operation, method|
      declared = declared_methods(operation)
      refute_empty declared, "#{operation}: no methods found in the RBI"

      walk(response_for(operation, method).data, declared, "#{operation}::Data") { checked += 1 }
    end
    # A guard against the walk silently doing nothing.
    assert_operator checked, :>, 25, 'too few fields exercised to mean anything'
  end

  def test_the_walk_notices_a_method_the_runtime_refuses
    # Same harness, given a field GetLedger does not select. If this passed, the
    # test above would prove nothing.
    data = stub_data('GetLedger')
    data.fetch('ledger')['schema'] = { 'key' => 's' }
    ledger = client_with(data).get_ledger({ ik: 'k' }).data.ledger

    assert_raises(GraphQL::Client::ImplicitlyFetchedFieldError) { ledger.schema }
  end

  private

  # `{ 'GetLedger::Data' => ['ledger'], 'GetLedger::Data::Ledger' => [...] }`
  def declared_methods(operation)
    path = []
    result = {}
    inside = false
    File.readlines(SNAPSHOT).each do |line|
      case line
      when /^module FragmentClient::Responses$/
        inside = true
        path = []
      when /^\S/
        # Any other top-level declaration ends the Responses module.
        inside = false
      end
      next unless inside

      case line
      when /^(\s+)class (\w+)$/
        path = path.first(Regexp.last_match(1).length / 2 - 1)
        path << Regexp.last_match(2)
      when /^(\s+)def (\w+); end$/
        # A `def` can sit at a shallower indent than the class just closed above
        # it, so the owning scope comes from this line's own indent.
        key = path.first(Regexp.last_match(1).length / 2 - 1).join('::')
        (result[key] ||= []) << Regexp.last_match(2) if key.start_with?("#{operation}::Data")
      end
    end
    result
  end

  # Walk the runtime object tree, asserting each declared method answers.
  def walk(node, declared, path, &block)
    (declared[path] || []).each do |name|
      value = node.public_send(name)
      block.call
      child = value.is_a?(Array) ? value.first : value
      next if child.nil?

      nested = "#{path}::#{camelize(name)}"
      walk(child, declared, nested, &block) if declared.key?(nested)
    end
  end

  def camelize(name)
    ActiveSupport::Inflector.camelize(name)
  end

  def response_for(operation, method)
    client_with(stub_data(operation)).public_send(method, {})
  end

  # Response data built from the operation's own selection set, so a fixture can
  # never drift from the query the way a hand-written one does.
  def stub_data(operation_name)
    op = FragmentGraphQl.operations.fetch(operation_name)
    build(op.selections, op.operation_type == 'mutation' ? schema.mutation : schema.query)
  end

  def build(selections, type)
    selections.each_with_object({}) do |selection, out|
      case selection
      when GraphQL::Language::Nodes::InlineFragment
        branch = selection.type ? schema.types[selection.type.name] : type
        out.merge!(build(selection.selections, branch)) if branch
      when GraphQL::Language::Nodes::Field
        name = selection.alias || selection.name
        next out[name] = 'X' if selection.name == '__typename'

        field = type.fields[selection.name]
        out[name] = value_for(field, selection) unless field.nil?
      end
    end
  end

  def value_for(field, selection)
    bare = field.type.non_null? ? field.type.of_type : field.type
    return [leaf_or_object(bare.of_type.unwrap, selection)] if bare.list?

    leaf_or_object(bare.unwrap, selection)
  end

  def leaf_or_object(unwrapped, selection)
    return build(selection.selections, unwrapped) unless selection.selections.empty?

    return unwrapped.values.keys.first if unwrapped.kind.enum?

    case unwrapped.graphql_name
    when 'Boolean' then true
    when 'Int' then 1
    when 'Float' then 1.0
    else 'x'
    end
  end

  def schema
    FragmentGraphQl::FragmentSchema
  end

  def client_with(data)
    stub_request(:post, 'https://api.fragment.dev/graphql')
      .to_return(status: 200, body: { 'data' => data }.to_json)
    FragmentClient.new('id', 'secret')
  end
end
