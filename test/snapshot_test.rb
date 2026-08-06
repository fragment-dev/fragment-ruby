# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'logger'
require 'minitest/autorun'
require 'tapioca/internal'
require 'tapioca/dsl/compilers/fragment_typed_entries'
require 'tapioca/dsl/compilers/fragment_query_methods'
require 'tapioca/dsl/compilers/fragment_response_types'

# Snapshot of the RBI the Tapioca DSL compiler generates.
#
# Spec 2.6 requires code generation to be backward-compatible across additive and
# order-only Schema changes: adding an entry type or a new version of one,
# reordering parameters, and adding an optional parameter must none of them break
# caller source. That guarantee is about generated identifiers and signatures, so
# it is not expressible in the shared language-neutral fixtures -- each SDK has to
# carry its own snapshot instead, so any change surfaces as a reviewable diff
# rather than silently.
#
# In Ruby the payload classes are built at load time, not generated to disk, so
# the artifact worth snapshotting is the RBI: it is the only durable, reviewable
# description of the surface a caller (and Sorbet) sees.
#
# The snapshot lives under `sorbet/` rather than beside this test so that `srb tc`
# checks it too, and so `sorbet/type_checks/typed_entries.rb` can call into it. A
# snapshot nothing typechecks could assert a signature Sorbet rejects and still
# pass. Not under `sorbet/rbi/dsl/`, though: that directory belongs to Tapioca,
# which deletes anything there it did not just generate.
#
# Regenerate with `bundle exec rake snapshot` and read the diff.
class SnapshotTest < Minitest::Test
  COMPILERS = [Tapioca::Dsl::Compilers::FragmentTypedEntries,
               Tapioca::Dsl::Compilers::FragmentQueryMethods,
               Tapioca::Dsl::Compilers::FragmentResponseTypes].freeze

  FIXTURE = File.expand_path('fixtures/snapshot_entries.graphql', __dir__)
  SNAPSHOT = File.expand_path('../sorbet/snapshots/typed_entries.rbi', __dir__)

  HEADER = <<~RBI
    # DO NOT EDIT MANUALLY
    # Snapshot of the RBI that `bundle exec tapioca dsl` generates for the typed
    # Ledger Entry payloads `FragmentClient::TypedEntries.load` builds at load
    # time. Regenerate with `bundle exec rake snapshot`.
    #
    # In this repository the payloads come from test/fixtures/snapshot_entries.graphql,
    # a synthetic Schema shaped to exercise every branch of the derivation. The
    # entry types below are not real Fragment entry types -- they exist so that
    # `test/snapshot_test.rb` has a reviewable diff and `srb tc` has something to
    # check. In your own application the equivalent file lands in
    # `sorbet/rbi/dsl/`, generated from your Schema's operations.

  RBI

  def setup
    FragmentClient.configure { |config| config.logger = Logger.new(File::NULL) }
    FragmentClient::TypedEntries.reset!
    FragmentGraphQl.reset_operations!
  end

  def teardown
    FragmentClient::TypedEntries.reset!
    FragmentGraphQl.reset_operations!
    FragmentClient.instance_variable_set(:@configuration, nil)
  end

  def test_generated_rbi_matches_the_snapshot
    actual = self.class.generate

    if ENV['RECORD_SNAPSHOTS']
      FileUtils.mkdir_p(File.dirname(SNAPSHOT))
      File.write(SNAPSHOT, actual)
      skip 'recorded snapshot'
    end

    assert_equal File.read(SNAPSHOT), actual, <<~MESSAGE
      The generated RBI no longer matches sorbet/snapshots/typed_entries.rbi.

      Every difference here is a change to the surface a caller touches. Renaming
      or removing anything, or turning an optional parameter into a required one,
      breaks existing call sites for what may be a purely additive Schema change
      (spec 2.6).

      If the change is intended, regenerate with `bundle exec rake snapshot`.
    MESSAGE
  end

  # What the fixture has to keep reaching for the snapshot to be worth having.
  BRANCHES = {
    'an escaped parameter name' => :escaped?.to_proc,
    'an optional parameter' => ->(p) { !p.required },
    'a list-typed parameter' => ->(p) { p.graphql_type.start_with?('[') },
    'a nullable list element' => ->(p) { p.graphql_type == '[String]' },
    'a non-String scalar' => ->(p) { p.graphql_type.start_with?('Int96') },
    'an Integer-typed parameter' => ->(p) { p.graphql_type == 'Int' },
    'a Boolean-typed parameter' => ->(p) { p.graphql_type == 'Boolean!' },
    'a required type with no Sorbet mapping' => ->(p) { p.graphql_type == 'TransferMode!' },
    # An unmapped type that is also optional: the unset sentinel must not be
    # folded into `T.untyped`, which already includes nil.
    'an optional type with no Sorbet mapping' => ->(p) { p.graphql_type == 'TransferChannel' }
  }.freeze

  def test_every_shipped_operation_gets_a_method
    # The query methods are defined per instance, so the RBI is the only thing
    # that tells Sorbet they exist. `add_ledger_entries` is excluded because it has
    # a hand-written signature; a duplicate declaration here would conflict.
    rbi = self.class.generate

    (FragmentGraphQl.operation_method_names - FragmentClient::WRAPPED_OPERATIONS).each do |name|
      assert_includes rbi, "  def #{name}(variables); end", "#{name} is missing from the RBI"
    end
    FragmentClient::WRAPPED_OPERATIONS.each do |name|
      refute_includes rbi, "  def #{name}(variables); end", "#{name} must not be redeclared"
    end
  end

  def test_the_fixture_exercises_every_branch_worth_snapshotting
    # A snapshot only guards what it covers. If the fixture stops reaching one of
    # these, the snapshot silently stops protecting it.
    FragmentClient::TypedEntries.load(FIXTURE, namespace: Module.new)
    registry = FragmentClient::TypedEntries.registry
    parameters = registry.values.flat_map(&:parameters)

    BRANCHES.each do |description, predicate|
      assert parameters.any? { |parameter| predicate.call(parameter) },
             "the fixture no longer covers #{description}"
    end

    assert_equal 5, registry.length, 'entry type coverage changed'
    assert_equal [1, 2],
                 registry.keys.select { |type, _| type == 'user-funds-account' }.map(&:last),
                 'the fixture no longer covers one entry type at two versions'
  end

  # Runs the real compiler through Tapioca's pipeline, so the snapshot is the RBI
  # `bundle exec tapioca dsl` would write and not a second renderer that could
  # drift from it.
  def self.generate
    FragmentClient::TypedEntries.reset!
    # Tapioca memoises each compiler's constant set, and intersects it with the
    # requested constants by identity. `reset!` above replaces the payload classes,
    # so without this a second call in one process matches none of them.
    COMPILERS.each(&:reset_state)
    # Into the real namespace: a class reached only through an anonymous module is
    # named `#<Module:0x...>::AuthCaptureV1`, which Sorbet cannot resolve and the
    # compiler therefore skips.
    payloads = FragmentClient::TypedEntries.load(FIXTURE)

    pipeline = Tapioca::Dsl::Pipeline.new(
      requested_constants: payloads + [FragmentClient],
      requested_compilers: COMPILERS,
      # In this process rather than forked workers. Tapioca parallelises with
      # `Parallel.map(in_processes:)`, and work done in a fork is invisible to
      # both SimpleCov and any failure this test would otherwise report directly.
      number_of_workers: 1
    )

    # One file rather than Tapioca's file-per-constant, because a single snapshot
    # is what makes the diff readable.
    bodies = pipeline.run { |constant, rbi| [constant.name, rbi.string] }
                     .sort_by(&:first)
                     .map { |_name, body| body.sub(/\A# typed: true\n\n/, '') }

    "#{HEADER}# typed: true\n\n#{bodies.join("\n")}"
  end
end
