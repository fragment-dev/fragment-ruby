# frozen_string_literal: true
# typed: true

require 'json'
require 'logger'
require 'minitest/autorun'
require 'fragment_client'

# Runner over the shared conformance fixtures in `test/spec/conformance`.
#
# The fixtures are language-neutral and shared by all four SDKs; only this runner
# is Ruby-specific. Each fixture directory holds `input.graphql` (operations fed
# to the derivation), `case.json` (the logical batch) and `expected.json` (the
# JSON this SDK must produce).
#
# `case.json` names payloads by entry type and version, never by generated class
# name, and identifies parameters by their Schema (wire) name. Resolving both is
# the runner's job -- and doing so exercises the local-name mapping that spec
# 2.5 and 3.3 are about.
class ConformanceTest < Minitest::Test
  FIXTURES_DIR = File.expand_path('spec/conformance', __dir__)

  # Values `case.json` may set on top of the parameters, per the fixture format.
  # `ik` and `ledgerIk` are handled separately because they are always present.
  COMMON_FIELDS = %w[posted description tags groups conditions].freeze

  def setup
    # Fixture 003 legitimately warns about escaped parameter names. Route it
    # somewhere quiet; `TypedEntriesTest` asserts on the warnings themselves.
    FragmentClient.configure { |config| config.logger = Logger.new(File::NULL) }
    FragmentClient::TypedEntries.reset!
  end

  def teardown
    FragmentClient::TypedEntries.reset!
    FragmentClient.instance_variable_set(:@configuration, nil)
    super
  end

  Dir.children(FIXTURES_DIR).sort.each do |fixture|
    define_method(:"test_#{fixture.tr('-', '_')}") { assert_conforms(fixture) }
  end

  def test_every_fixture_is_covered
    # A fixture added upstream and synced down must not sit unnoticed: without
    # this, a new directory simply defines a test nobody notices is missing.
    assert_equal 6, Dir.children(FIXTURES_DIR).length,
                 'Fixture count changed. Confirm the new fixture has a passing test, ' \
                 'then update this count and docs/spec-conformance.md.'
  end

  private

  def assert_conforms(fixture)
    dir = File.join(FIXTURES_DIR, fixture)

    # Into a throwaway namespace so fixtures cannot see each other's classes.
    FragmentClient::TypedEntries.load_string(
      File.read(File.join(dir, 'input.graphql')), namespace: Module.new
    )

    batch = read_json(dir, 'case.json')
    actual = { 'entries' => batch.fetch('entries').map { |entry| build(entry).to_entry_input } }
    expected = read_json(dir, 'expected.json')

    # Baseline equivalence profile: same key set, nesting and values, with unset
    # fields omitted. Hash equality ignores order, so this says nothing about it.
    assert_equal expected, actual, "#{fixture} does not conform (baseline profile)"

    # Strict profile: byte equality. `JSON.parse` preserves the fixture's key
    # order, so re-generating it yields the bytes an SDK on the strict profile
    # must emit. This is the assertion that catches a reordered `parameters`
    # payload -- the baseline one cannot.
    assert_equal JSON.generate(expected), JSON.generate(actual),
                 "#{fixture} does not conform (strict profile: key order or encoding)"
  end

  def build(entry)
    klass = FragmentClient::TypedEntries.fetch(
      entry.fetch('type'), entry.fetch('typeVersion', FragmentClient::TypedEntries::DEFAULT_TYPE_VERSION)
    )

    arguments = { ik: entry.fetch('ik'), ledger_ik: entry.fetch('ledgerIk') }
    COMMON_FIELDS.each { |field| arguments[field.to_sym] = entry[field] if entry.key?(field) }
    entry.fetch('parameters', {}).each do |wire_name, value|
      arguments[local_name(klass, wire_name)] = value
    end

    klass.new(**arguments)
  end

  def local_name(klass, wire_name)
    parameter = klass.parameters.find { |candidate| candidate.wire_name == wire_name }
    refute_nil parameter,
               "#{klass.entry_type.inspect} declares no parameter #{wire_name.inspect}; " \
               "derived: #{klass.parameters.map(&:wire_name).inspect}"
    parameter.name
  end

  def read_json(dir, name)
    JSON.parse(File.read(File.join(dir, name)))
  end
end

# Spec 3.4's optional strict profile: keys in lexicographic order by wire name at
# every level, except `parameters`, which keeps the source order of spec 2.4.
#
# Ruby hashes are insertion-ordered and `JSON.generate` neither escapes non-ASCII
# nor `<`/`>`/`&`, so this SDK satisfies the strict profile as well as the
# baseline. Asserted rather than assumed, since nothing in the code would fail if
# a field were inserted out of order.
class CanonicalKeyOrderTest < Minitest::Test
  FIXTURES_DIR = File.expand_path('spec/conformance', __dir__)

  def setup
    FragmentClient.configure { |config| config.logger = Logger.new(File::NULL) }
    FragmentClient::TypedEntries.reset!
  end

  def teardown
    FragmentClient::TypedEntries.reset!
    FragmentClient.instance_variable_set(:@configuration, nil)
    super
  end

  def test_key_order_is_canonical
    Dir.children(FIXTURES_DIR).sort.each do |fixture|
      dir = File.join(FIXTURES_DIR, fixture)
      FragmentClient::TypedEntries.load_string(
        File.read(File.join(dir, 'input.graphql')), namespace: Module.new
      )
      batch = JSON.parse(File.read(File.join(dir, 'case.json')))

      batch.fetch('entries').each do |entry|
        klass = FragmentClient::TypedEntries.fetch(
          entry.fetch('type'), entry.fetch('typeVersion', 1)
        )
        payload = build_minimally(klass, entry)
        assert_canonical(payload.to_entry_input, klass, fixture)
      end

      FragmentClient::TypedEntries.reset!
    end
  end

  def test_parameters_keep_source_order_not_required_first
    # 004-param-order declares alpha, bravo, charlie, of which bravo is the only
    # optional one. Sorting required-first would move bravo to the end.
    klass = load_fixture('004-param-order', 'ordered')

    assert_equal %w[alpha bravo charlie], klass.parameters.map(&:wire_name)
  end

  def test_parameters_keep_source_order_not_alphabetical
    # 004's own order happens to be alphabetical, so it cannot distinguish source
    # order from a sort. 001's can: `capture_amount` precedes `user_id`
    # alphabetically but follows it in the source operation.
    klass = load_fixture('001-basic', 'auth_capture')

    assert_equal %w[user_id capture_amount], klass.parameters.map(&:wire_name)
  end

  def load_fixture(fixture, entry_type)
    FragmentClient::TypedEntries.load_string(
      File.read(File.join(FIXTURES_DIR, fixture, 'input.graphql')), namespace: Module.new
    )
    FragmentClient::TypedEntries.fetch(entry_type)
  end

  private

  def build_minimally(klass, entry)
    arguments = { ik: entry.fetch('ik'), ledger_ik: entry.fetch('ledgerIk') }
    entry.fetch('parameters', {}).each do |wire_name, value|
      parameter = klass.parameters.find { |candidate| candidate.wire_name == wire_name }
      arguments[parameter.name] = value if parameter
    end
    klass.new(**arguments)
  end

  def assert_canonical(input, klass, fixture)
    assert_equal input.keys.sort, input.keys, "#{fixture}: top-level keys out of order"

    # `parameters` itself sorts among its siblings; only its contents are exempt.
    entry = input.fetch('entry')
    assert_equal entry.keys.sort, entry.keys, "#{fixture}: entry keys out of order"

    supplied = entry.fetch('parameters').keys
    source_order = klass.parameters.map(&:wire_name) & supplied
    assert_equal source_order, supplied, "#{fixture}: parameters not in source order"
  end
end
