# frozen_string_literal: true
# typed: true

require 'minitest/autorun'
require 'webmock/minitest'
require 'fragment_client'

class UnitTest < Minitest::Test
  include WebMock::API

  MOCK_SUCCESSFUL_RESPONSE = {
    "data" => {
      "createLedger" => {
        "ledger" => {
          "id" => "123",
          "ik" => "test_ik",
          "name" => "Test Ledger",
          "created" => "2024-03-14T00:00:00Z",
          "schema" => {
            "key" => "test_schema"
          }
        },
        "isIkReplay" => false
      }
    }
  }.freeze

  def setup
    # Reset configuration before each test
    FragmentClient.instance_variable_set(:@configuration, nil)
    
    # Stub the default successful auth response
    stub_request(:post, "https://auth.fragment.dev/oauth2/token")
      .to_return(status: 200, body: { access_token: "test_token", expires_in: 3600 }.to_json)

    # Stub the default successful GraphQL response
    stub_request(:post, "https://api.fragment.dev/graphql")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'Authorization' => /Bearer .+/,
          'X-Fragment-Client' => /ruby-client@.+/
        }
      )
      .to_return(status: 200, body: MOCK_SUCCESSFUL_RESPONSE.to_json)
  end

  def test_that_client_works_with_mock_response
    body = '{"query":"mutation FragmentGraphQl__FragmentQueries__CreateLedger($ik: SafeString!, $ledger: CreateLedgerInput!, $schemaKey: SafeString!) {\
  createLedger(ik: $ik, ledger: $ledger, schema: {key: $schemaKey}) {\
    __typename\
    ... on CreateLedgerResult {\
      ledger {\
        id\
        ik\
        name\
        created\
        schema {\
          key\
        }\
      }\
      isIkReplay\
    }\
    ... on Error {\
      code\
      message\
    }\
  }\
}","operationName":"FragmentGraphQl__FragmentQueries__CreateLedger"}'
    stub_request(:post, 'https://api.fragment.dev/graphql')
      .with(
        body: body.gsub("\\\n", '\\n'),
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer mock_token',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body:
       '{"data": {"createLedger":{"__typename": "CreateLedgerResult", "ledger": {"name": "bert"}}}}',
                 headers: {})

    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .with(body: /grant_type=client_credentials&scope=.+&client_id=.+/)
      .to_return(status: 200, body: '{"access_token":"mock_token","expires_in":3600}', headers: {})

    client = FragmentClient.new('user_id', 'api_key', api_url: 'https://api.fragment.dev/graphql', oauth_url: 'https://auth.fragment.dev/oauth2/token')
    response = client.create_ledger({})
    assert_equal(response.data.create_ledger.ledger.name, 'bert')
  end

  def test_authentication_error_on_invalid_credentials
    stub_request(:post, "https://auth.fragment.dev/oauth2/token")
      .to_return(status: 401, body: "Invalid credentials")

    error = assert_raises(FragmentClient::AuthenticationError) do
      FragmentClient.new("bad_id", "bad_secret")
    end
    assert_match(/Invalid credentials/, error.message)
  end

  def test_authentication_error_on_server_error
    stub_request(:post, "https://auth.fragment.dev/oauth2/token")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(FragmentClient::AuthenticationError) do
      FragmentClient.new("client_id", "client_secret")
    end
    assert_match(/Authentication failed \(500\)/, error.message)
  end

  def test_authentication_error_on_invalid_json
    stub_request(:post, "https://auth.fragment.dev/oauth2/token")
      .to_return(status: 200, body: "not json")

    error = assert_raises(FragmentClient::AuthenticationError) do
      FragmentClient.new("client_id", "client_secret")
    end
    assert_match(/Invalid response format/, error.message)
  end

  def test_token_refresh_before_expiry
    # Setup initial token
    stub_request(:post, "https://auth.fragment.dev/oauth2/token")
      .to_return(status: 200, body: { access_token: "token1", expires_in: 10 }.to_json)
      .then.to_return(status: 200, body: { access_token: "token2", expires_in: 3600 }.to_json)

    # Stub GraphQL requests with both tokens
    stub_request(:post, "https://api.fragment.dev/graphql")
      .with(
        headers: {
          'Authorization' => 'Bearer token2',
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'X-Fragment-Client' => /ruby-client@.+/
        }
      )
      .to_return(status: 200, body: MOCK_SUCCESSFUL_RESPONSE.to_json)

    FragmentClient.configure do |config|
      config.token_expiry_buffer = 5 # Set buffer to 5 seconds
    end

    client = FragmentClient.new("client_id", "client_secret")
    
    Time.stub :now, Time.now + 6 do
      response = client.query(FragmentGraphQl::FragmentQueries::CreateLedger, {
        ik: "test_ik",
        ledger: { name: "Test Ledger" },
        schemaKey: "test_schema"
      })
      assert_equal "token2", client.instance_variable_get(:@token).token
    end
  end

  def test_extra_queries_file
    # Setup token
    stub_request(:post, "https://auth.fragment.dev/oauth2/token")
      .to_return(status: 200, body: { access_token: "token1", expires_in: 3600 }.to_json)

    # Create temp file with query
    query_file = Tempfile.new(['test_extra_queries', '.graphql'])
    query_file.write(<<~GRAPHQL)
      mutation PostInitialFunding($ik: SafeString!, $ledgerIk: SafeString!, $funding_amount: String!) {
        addLedgerEntry(
          ik: $ik
          entry: {ledger: {ik: $ledgerIk}, type: "initial_funding", parameters: {funding_amount: $funding_amount}}
        ) {
          __typename
          ... on AddLedgerEntryResult {
            entry {
              ik
              id
              created
              type
              posted
              description
              ledger {
                ik
              }
              tags {
                key
                value
              }
              groups {
                key
                value
              }
            }
            lines {
              account {
                path
              }
              amount
              currency {
                code
                customCurrencyId
              }
              key
            }
            isIkReplay
          }
          ... on Error {
            code
            message
            retryable
          }
        }
      }
    GRAPHQL
    query_file.close

    # Stub GraphQL request
    stub_request(:post, "https://api.fragment.dev/graphql")
      .with(
        headers: {
          'Authorization' => 'Bearer token1',
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'X-Fragment-Client' => /ruby-client@.+/
        }
      )
      .to_return(status: 200, body: MOCK_SUCCESSFUL_RESPONSE.to_json)

    client = FragmentClient.new(
      "client_id", 
      "client_secret",
      extra_queries_filenames: [query_file.path]
    )

    # Verify the post_initial_funding method was defined
    assert client.respond_to?(:post_initial_funding)

    # Clean up
    query_file.unlink
  end
end
