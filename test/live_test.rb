# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'json'
require 'logger'
require 'minitest/autorun'
require 'securerandom'

# The API gates the batch endpoint behind `x-fragment-experimental` until its
# per-entry error contract is settled. That requirement is being removed, so the
# header is injected here rather than added to the SDK -- shipping an option for a
# gate that is about to disappear would leave a deprecated keyword behind.
#
# Delete this module and its `prepend` once the gate is gone; nothing else depends
# on it.
module ExperimentalHeader
  def headers(context)
    super.merge('x-fragment-experimental' => 'true')
  end
end
FragmentGraphQl::CustomHTTP.prepend(ExperimentalHeader)

# Against the real API. Skipped unless `FRAGMENT_CREDENTIALS` points at a JSON file
# of `clientId`, `clientSecret`, `apiUrl`, `authUrl`, `scope`.
#
# These answer a question no offline test can: the shared spec records "server
# tolerance for an entry object with `lines` absent and `type` present is untested in
# every SDK", and every offline test here passed while the endpoint was in fact
# unreachable.
#
# Writes are confined to a ledger created and deleted per run, so nothing existing
# is touched.
class LiveTest < Minitest::Test
  CREDENTIALS = ENV.fetch('FRAGMENT_CREDENTIALS', nil)
  SCHEMA_KEY = ENV.fetch('FRAGMENT_LIVE_SCHEMA', 'foo')
  ENTRY_TYPE = ENV.fetch('FRAGMENT_LIVE_ENTRY_TYPE', 'new-entry')
  OPERATIONS = File.expand_path('live/entries.graphql', __dir__)

  def setup
    skip 'set FRAGMENT_CREDENTIALS to run the live tests' if CREDENTIALS.nil?

    FragmentClient.instance_variable_set(:@configuration, nil)
    FragmentClient.configure { |config| config.logger = Logger.new(File::NULL) }
    FragmentClient::TypedEntries.reset!
    FragmentGraphQl.reset_operations!
    @ledger_ik = "ruby-sdk-live-#{SecureRandom.hex(6)}"
    @created = false
  end

  def teardown
    delete_ledger if @created
    FragmentClient::TypedEntries.reset!
    FragmentGraphQl.reset_operations!
    FragmentClient.instance_variable_set(:@configuration, nil)
  end

  def test_a_read_only_query_round_trips
    workspace = client.get_workspace({}).data.workspace

    refute_nil workspace.id
    refute_empty workspace.name
  end

  def test_an_entry_with_a_type_and_no_lines_is_accepted
    # The open question in the shared spec. A typed payload sends `type` and
    # `parameters` and deliberately omits `lines`.
    create_ledger
    entry = payload('spec-6-check')

    refute entry.to_h.fetch('entry').key?('lines'), 'the payload must not send lines'

    result = client.add_ledger_entries(entries: [entry]).data.add_ledger_entries

    assert_equal 'AddLedgerEntriesResult', result.__typename,
                 "server rejected it: #{result.respond_to?(:message) ? result.message : result}"
    assert_equal 1, result.results.length
    refute_empty result.results.first.lines, 'the server should have expanded the entry into lines'
  end

  def test_an_idempotency_key_replays_per_entry
    create_ledger
    entry = payload('replay-check')

    first = client.add_ledger_entries(entries: [entry]).data.add_ledger_entries
    assert_equal 'AddLedgerEntriesResult', first.__typename
    assert_equal [false], first.results.map(&:is_ik_replay)

    second = client.add_ledger_entries(entries: [entry]).data.add_ledger_entries
    assert_equal 'AddLedgerEntriesResult', second.__typename
    assert_equal [true], second.results.map(&:is_ik_replay), 'a repeated ik must report a replay'
    assert_equal first.results.first.entry.id, second.results.first.entry.id
  end

  def test_the_generated_response_types_hold_against_real_data
    # The offline agreement test builds its data from the selection set; this uses
    # what the API actually returns.
    ledger = client.get_ledger({ ik: SCHEMA_KEY }).data&.ledger
    skip "no ledger named #{SCHEMA_KEY} to read" if ledger.nil?

    assert_kind_of String, ledger.id
    assert_kind_of String, ledger.balance_utc_offset
  end

  private

  def credentials
    @credentials ||= JSON.parse(File.read(T.must(CREDENTIALS)))
  end

  def client
    FragmentClient.new(
      credentials.fetch('clientId'), credentials.fetch('clientSecret'),
      api_url: credentials.fetch('apiUrl'), oauth_url: credentials.fetch('authUrl'),
      oauth_scope: credentials.fetch('scope'), extra_queries_filenames: [OPERATIONS]
    )
  end

  def payload(ik)
    FragmentClient::TypedEntries.fetch(ENTRY_TYPE, 1)
                                .new(ik: ik, ledger_ik: @ledger_ik, amount: '100')
  end

  def create_ledger
    result = client.create_ledger(
      { ik: @ledger_ik, ledger: { name: 'ruby-sdk live test' }, schemaKey: SCHEMA_KEY }
    ).data.create_ledger
    assert_equal 'CreateLedgerResult', result.__typename,
                 "could not create a ledger: #{result.respond_to?(:message) ? result.message : result}"
    @created = true
  end

  # Retried, because a delete issued straight after writing entries comes back as a
  # BadRequestError and then succeeds a moment later. A single attempt left ledgers
  # behind in someone's workspace, which is worse than a slow teardown.
  def delete_ledger
    deleted = (0...5).any? do |attempt|
      sleep(0.4 * attempt) if attempt.positive?
      client.delete_ledger({ ledger: { ik: @ledger_ik } })
            .data.delete_ledger.__typename == 'DeleteLedgerResult'
    end
    flunk "live test could not delete ledger #{@ledger_ik}; delete it by hand" unless deleted
  rescue StandardError => e
    flunk "live test could not delete ledger #{@ledger_ik}: #{e.class}: #{e.message}"
  end
end
