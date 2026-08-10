# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'json'
require 'logger'
require 'minitest/autorun'
require 'tempfile'
require 'webmock/minitest'

# `FragmentClient#add_ledger_entries` end to end, through the real
# `graphql-client` transport.
#
# Everything a batch method accepts must serialize (spec 3.6). The unit tests
# assert on the hash `to_entry_input` builds; these assert on the bytes that
# leave the process, which is the only place a transport that mishandles a
# payload would show up.
class AddLedgerEntriesTest < Minitest::Test
  include WebMock::API

  OPERATIONS = <<~GQL
    mutation PostAuthCapture($ik: SafeString!, $ledgerIk: SafeString!, $user_id: String!, $capture_amount: String!) {
      addLedgerEntry(ik: $ik, entry: {ledger: {ik: $ledgerIk}, type: "auth_capture", parameters: {user_id: $user_id, capture_amount: $capture_amount}}) {
        __typename
      }
    }
  GQL

  def setup
    FragmentClient.instance_variable_set(:@configuration, nil)
    FragmentClient.configure { |config| config.logger = Logger.new(File::NULL) }
    FragmentClient::TypedEntries.reset!
    FragmentGraphQl.reset_operations!

    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json)

    @queries_file = Tempfile.new(['typed_entries', '.graphql'])
    @queries_file.write(OPERATIONS)
    @queries_file.close
  end

  def teardown
    @queries_file.unlink
    FragmentClient::TypedEntries.reset!
    FragmentGraphQl.reset_operations!
    FragmentClient.instance_variable_set(:@configuration, nil)
    super
  end

  def test_constructing_a_client_registers_typed_payloads_from_extra_queries
    client = build_client

    # The per-entry-type operations arrive in exactly these files, so passing
    # them is all a caller has to do.
    assert_respond_to client, :post_auth_capture
    assert_equal 'auth_capture', FragmentClient::Entries::AuthCaptureV1.entry_type
  end

  def test_the_variables_hash_form_works_like_every_other_operation_method
    # Someone reading queries.graphql writes the variables hash directly, and the
    # keyword form is the same call in Ruby. Both must reach the same request.
    entry = { ik: 'raw-1', entry: { ledger: { ik: 'prod' }, type: 't' } }
    positional = capture_request(extra_queries: false) { |c| c.add_ledger_entries({ entries: [entry] }) }
    keyword = capture_request(extra_queries: false) { |c| c.add_ledger_entries(entries: [entry]) }

    assert_equal positional.dig('variables', 'entries'), keyword.dig('variables', 'entries')
    assert_equal 'raw-1', keyword.dig('variables', 'entries', 0, 'ik')
  end

  def test_a_payload_converts_to_a_hash_under_either_name
    FragmentClient::TypedEntries.load_string(OPERATIONS)
    entry = FragmentClient::Entries::AuthCaptureV1.new(
      ik: 'ik-1', ledger_ik: 'prod', user_id: 'u', capture_amount: '1'
    )

    assert_equal entry.to_entry_input, entry.to_h
  end

  def test_raw_entries_work_without_loading_any_typed_payloads
    # The batch method is not conditional on the typed-payload machinery: a client
    # constructed with no extra queries still posts a batch of plain hashes, which
    # is the first example in the README.
    entry = { ik: 'raw-1',
              entry: { ledger: { ik: 'prod' }, type: 'user_funds_account',
                       parameters: { user_id: 'user-1' } } }
    body = capture_request(extra_queries: false) do |client|
      client.add_ledger_entries(entries: [entry])
    end

    assert_empty FragmentClient::TypedEntries.registry
    assert_equal 'raw-1', body.dig('variables', 'entries', 0, 'ik')
    assert_equal 'user-1', body.dig('variables', 'entries', 0, 'entry', 'parameters', 'user_id')
  end

  def test_a_typed_payload_reaches_the_wire_as_an_add_ledger_entry_input
    body = capture_request do |client|
      client.add_ledger_entries(entries: [
                                  FragmentClient::Entries::AuthCaptureV1.new(
                                    ik: 'ik-1', ledger_ik: 'prod',
                                    user_id: 'user-1', capture_amount: '100'
                                  )
                                ])
    end

    assert_equal(
      [{ 'entry' => { 'ledger' => { 'ik' => 'prod' },
                      'parameters' => { 'user_id' => 'user-1', 'capture_amount' => '100' },
                      'type' => 'auth_capture', 'typeVersion' => 1 },
         'ik' => 'ik-1' }],
      body.dig('variables', 'entries')
    )
    assert_match(/AddLedgerEntries/, body.fetch('operationName'))
  end

  def test_the_hand_written_wrapper_is_not_shadowed_by_the_generated_one
    # `define_method_from_queries` defines a singleton method per operation, and
    # a singleton method beats an instance method. If `AddLedgerEntries` were not
    # in WRAPPED_OPERATIONS, this call would reach the generated method and the
    # payload object itself would go to the JSON encoder.
    body = capture_request do |client|
      client.add_ledger_entries(entries: [
                                  FragmentClient::Entries::AuthCaptureV1.new(
                                    ik: 'ik-1', ledger_ik: 'prod',
                                    user_id: 'u', capture_amount: '1'
                                  )
                                ])
    end

    entry = body.dig('variables', 'entries', 0)

    assert_kind_of Hash, entry
    refute_match(/AuthCaptureV1/, JSON.generate(body),
                 'a payload object reached the encoder instead of its input hash')
  end

  def test_typed_and_raw_entries_may_be_mixed_and_keep_their_order
    body = capture_request do |client|
      client.add_ledger_entries(entries: [
                                  FragmentClient::Entries::AuthCaptureV1.new(
                                    ik: 'typed', ledger_ik: 'prod', user_id: 'u', capture_amount: '1'
                                  ),
                                  { ik: 'raw', entry: { ledger: { ik: 'prod' }, type: 'other' } }
                                ])
    end

    entries = body.dig('variables', 'entries')

    assert_equal(%w[typed raw], entries.map { |entry| entry.fetch('ik') })
    assert_equal 'other', entries.dig(1, 'entry', 'type')
  end

  def test_non_ascii_and_html_significant_parameter_values_survive_the_transport
    # Spec 3.4: no SDK may escape these. Asserted on the raw body rather than the
    # parsed one, since parsing would hide `é`-style escaping.
    raw = nil
    capture_request(capture_raw: ->(body) { raw = body }) do |client|
      client.add_ledger_entries(entries: [
                                  FragmentClient::Entries::AuthCaptureV1.new(
                                    ik: 'ik-1', ledger_ik: 'prod',
                                    user_id: 'a&b <tag> café 日本', capture_amount: '1'
                                  )
                                ])
    end

    assert_includes raw, 'a&b <tag> café 日本'
  end

  def test_an_unset_field_is_absent_from_the_request_body
    raw = nil
    capture_request(capture_raw: ->(body) { raw = body }) do |client|
      client.add_ledger_entries(entries: [
                                  FragmentClient::Entries::AuthCaptureV1.new(
                                    ik: 'ik-1', ledger_ik: 'prod', user_id: 'u', capture_amount: '1'
                                  )
                                ])
    end

    # The transport must not reintroduce what the payload omitted.
    refute_match(/"description"/, raw)
    refute_match(/"posted"/, raw)
    refute_match(/null/, raw)
  end

  def test_per_entry_errors_are_surfaced_with_the_ik_that_identifies_them
    response = {
      'data' => {
        'addLedgerEntries' => {
          '__typename' => 'AddLedgerEntriesError',
          'code' => 'bad_request', 'message' => 'Some entries failed', 'retryable' => false,
          'errors' => [
            { 'ik' => 'ik-2', 'code' => 'invalid_parameters',
              'message' => 'capture_amount is required', 'retryable' => false }
          ]
        }
      }
    }
    stub_graphql(response)

    result = build_client.add_ledger_entries(entries: [
                                               FragmentClient::Entries::AuthCaptureV1.new(
                                                 ik: 'ik-2', ledger_ik: 'prod',
                                                 user_id: 'u', capture_amount: '1'
                                               )
                                             ]).data.add_ledger_entries

    assert_equal 'AddLedgerEntriesError', result.__typename
    # The `ik` is what tells a caller which entry to fix, so the list must not be
    # collapsed into the top-level message.
    assert_equal ['ik-2'], result.errors.map(&:ik)
    assert_equal 'capture_amount is required', result.errors.first.message
  end

  def test_results_are_returned_per_entry_with_ik_replay
    response = {
      'data' => {
        'addLedgerEntries' => {
          '__typename' => 'AddLedgerEntriesResult',
          'results' => [
            { 'isIkReplay' => true,
              'entry' => { 'type' => 'auth_capture', 'id' => '1', 'ik' => 'ik-1',
                           'posted' => '2026-01-01T00:00:00Z', 'created' => '2026-01-01T00:00:00Z' },
              'lines' => [] },
            { 'isIkReplay' => false,
              'entry' => { 'type' => 'auth_capture', 'id' => '2', 'ik' => 'ik-2',
                           'posted' => '2026-01-01T00:00:00Z', 'created' => '2026-01-01T00:00:00Z' },
              'lines' => [] }
          ]
        }
      }
    }
    stub_graphql(response)

    results = build_client.add_ledger_entries(entries: [
                                                payload('ik-1'), payload('ik-2')
                                              ]).data.add_ledger_entries.results

    # Idempotency keys are per entry, not per batch, so a partially replayed
    # batch reports which entries had already committed.
    assert_equal [true, false], results.map(&:is_ik_replay)
    assert_equal(%w[ik-1 ik-2], results.map { |result| result.entry.ik })
  end

  private

  def payload(ik)
    FragmentClient::Entries::AuthCaptureV1.new(
      ik: ik, ledger_ik: 'prod', user_id: 'u', capture_amount: '1'
    )
  end

  def build_client(extra_queries: true)
    filenames = extra_queries ? [@queries_file.path] : nil
    FragmentClient.new('client_id', 'client_secret', extra_queries_filenames: filenames)
  end

  def stub_graphql(response)
    stub_request(:post, 'https://api.fragment.dev/graphql')
      .to_return(status: 200, body: response.to_json)
  end

  def capture_request(capture_raw: nil, extra_queries: true)
    captured = nil
    stub_request(:post, 'https://api.fragment.dev/graphql').to_return do |request|
      captured = request.body
      capture_raw&.call(request.body)
      { status: 200, body: { 'data' => { 'addLedgerEntries' => { '__typename' => 'InternalError',
                                                                 'code' => 'e', 'message' => 'm',
                                                                 'retryable' => true } } }.to_json }
    end

    yield build_client(extra_queries: extra_queries)

    refute_nil captured, "request body wasn't captured"
    JSON.parse(captured)
  end
end
