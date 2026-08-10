# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'minitest/autorun'
require 'webmock/minitest'
require 'base64'

class UnitTest < Minitest::Test
  include WebMock::API

  MOCK_SUCCESSFUL_RESPONSE = {
    'data' => {
      'createLedger' => {
        'ledger' => {
          'id' => '123',
          'ik' => 'test_ik',
          'name' => 'Test Ledger',
          'created' => '2024-03-14T00:00:00Z',
          'schema' => {
            'key' => 'test_schema'
          }
        },
        'isIkReplay' => false
      }
    }
  }.freeze

  def setup
    # Reset configuration before each test
    FragmentClient.instance_variable_set(:@configuration, nil)

    # Stub the default successful auth response
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json)

    # Stub the default successful GraphQL response
    stub_request(:post, 'https://api.fragment.dev/graphql')
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
    ... on BadRequestError {\
      code\
      message\
      retryable\
    }\
    ... on InternalError {\
      code\
      message\
      retryable\
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
       '{"data": {"createLedger":{"__typename": "CreateLedgerResult", "ledger": {"name": "bert", "id": "123", "ik": "test_ik", "created": "2024-03-14T00:00:00Z", "schema": {"key": "test_schema"}}, "isIkReplay": false}}}',
                 headers: {})

    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .with(body: /grant_type=client_credentials&scope=.+&client_id=.+/)
      .to_return(status: 200, body: '{"access_token":"mock_token","expires_in":3600}', headers: {})

    client = FragmentClient.new('user_id', 'api_key', api_url: 'https://api.fragment.dev/graphql', oauth_url: 'https://auth.fragment.dev/oauth2/token')
    response = client.create_ledger({})
    assert_equal(response.data.create_ledger.ledger.name, 'bert')
  end

  def test_authentication_error_on_invalid_credentials
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 401, body: 'Invalid credentials')

    error = assert_raises(FragmentClient::AuthenticationError) do
      FragmentClient.new('bad_id', 'bad_secret')
    end
    assert_match(/Invalid credentials/, error.message)
  end

  def test_authentication_error_on_server_error
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 500, body: 'Internal Server Error')

    error = assert_raises(FragmentClient::AuthenticationError) do
      FragmentClient.new('client_id', 'client_secret')
    end
    assert_match(/Authentication failed \(500\)/, error.message)
  end

  def test_authentication_error_on_invalid_json
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 200, body: 'not json')

    error = assert_raises(FragmentClient::AuthenticationError) do
      FragmentClient.new('client_id', 'client_secret')
    end
    assert_match(/Invalid response format/, error.message)
  end

  def test_token_refresh_before_expiry
    # Setup initial token
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 'token1', expires_in: 10 }.to_json)
      .then.to_return(status: 200, body: { access_token: 'token2', expires_in: 3600 }.to_json)

    # Stub GraphQL requests with both tokens
    stub_request(:post, 'https://api.fragment.dev/graphql')
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

    client = FragmentClient.new('client_id', 'client_secret')

    Time.stub :now, Time.now + 6 do
      client.query(FragmentGraphQl::FragmentQueries::CreateLedger, {
                     ik: 'test_ik',
                     ledger: { name: 'Test Ledger' },
                     schemaKey: 'test_schema'
                   })
      assert_equal 'token2', client.instance_variable_get(:@token).token
    end
  end

  def test_extra_queries_file
    # Setup token
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 'token1', expires_in: 3600 }.to_json)

    # Create temp file with query
    query_file = Tempfile.new(['test_extra_queries', '.graphql'])
    query_file.write(<<~GRAPHQL)
      query Buzz(
        $ledgerAccount: LedgerAccountMatchInput!
        ) {
        ledgerAccount(ledgerAccount: $ledgerAccount) {
          path
          name
          balances {
            nodes {
              amount
              currency {
                code
                customCurrencyId
              }
            }
          }
          end_of_year_balances: balances(at: "1969") {
            nodes {
              amount
              currency {
                code
                customCurrencyId
              }
            }
          }
          last_year: balanceChanges(period: "1968") {
            nodes {
              amount
              currency {
                code
                customCurrencyId
              }
            }
          }
        }
        }
    GRAPHQL
    query_file.close

    # Use a variable to capture the request body
    captured_body = nil

    # Stub GraphQL request with callback to capture the body
    stub_request(:post, 'https://api.fragment.dev/graphql')
      .with(headers: {
              'Authorization' => 'Bearer token1',
              'Accept' => 'application/json',
              'Content-Type' => 'application/json',
              'X-Fragment-Client' => /ruby-client@.+/
            })
      .to_return do |request|
        captured_body = request.body
        { status: 200, body: MOCK_SUCCESSFUL_RESPONSE.to_json }
      end

    client = FragmentClient.new(
      'client_id',
      'client_secret',
      extra_queries_filenames: [query_file.path]
    )

    # Verify the buzz method was defined
    assert_respond_to client, :buzz

    # Make a query
    client.buzz(ledgerAccount: { path: 'assets', ledger: { ik: 'credit-cards-example' } })

    # Verify we captured the body
    refute_nil captured_body, "Request body wasn't captured"

    # Parse the request body
    body_json = JSON.parse(captured_body)

    # Make specific assertions about the body
    assert_match(/FragmentGraphQl__Dynamic__Custom__Buzz/, body_json['query'], "Query doesn't contain expected operation name")
    assert_match(/FragmentGraphQl__Dynamic__Custom__Buzz/, body_json['operationName'], "OperationName doesn't match expected format")
    assert_equal(
      {
        'path' => 'assets',
        'ledger' => {
          'ik' => 'credit-cards-example'
        }
      },
      body_json['variables']['ledgerAccount'],
      "Variables don't match expected structure"
    )

    # Clean up
    query_file.unlink
  end

  def test_token_request_conforms_to_oauth2_and_http_specs
    # Intercept Net::HTTP::Post to capture the raw request-target path.
    # WebMock normalizes URLs before matching, so it cannot detect
    # absolute-form vs origin-form request-targets.
    captured_request_paths = []
    Net::HTTP::Post.define_method(:initialize) do |path, initheader = nil|
      captured_request_paths << path
      super(path, initheader)
    end

    captured_auth_request = nil
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return do |request|
        captured_auth_request = request
        { status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json }
      end

    begin
      FragmentClient.new('test_client_id', 'test_client_secret')

      # RFC 7230 §5.3.1: "When making a request directly to an origin server,
      # [...] a client MUST send only the absolute-path and query components
      # of the target URI as the request-target."
      token_request_path = captured_request_paths.first
      assert_equal '/oauth2/token', token_request_path,
                   "Token request must use origin-form request-target (RFC 7230 §5.3.1), got: #{token_request_path}"

      # RFC 6749 §4.4.2: "The client makes a request to the token endpoint by
      # adding the following parameters using the 'application/x-www-form-urlencoded'
      # format [...] grant_type: REQUIRED. Value MUST be set to 'client_credentials'."
      body_params = URI.decode_www_form(captured_auth_request.body).to_h
      assert_equal 'client_credentials', body_params['grant_type'],
                   'grant_type must be client_credentials (RFC 6749 §4.4.2)'

      # RFC 6749 §4.4.2: "scope: OPTIONAL."
      refute_nil body_params['scope'],
                 'scope parameter should be present when configured (RFC 6749 §4.4.2)'

      # RFC 6749 §4.4.2 requires the token request entity-body to use the
      # application/x-www-form-urlencoded format per Appendix B, and the
      # section's example request explicitly sets this Content-Type.
      content_type = captured_auth_request.headers['Content-Type']
      assert_match(%r{\Aapplication/x-www-form-urlencoded\b}, content_type,
                   'Token request Content-Type should be application/x-www-form-urlencoded (RFC 6749 §4.4.2)')

      # RFC 6749 §2.3.1: "Clients in possession of a client password MAY use
      # the HTTP Basic authentication scheme [...] The client identifier is [...]
      # used as the username; the client password [...] used as the password."
      auth_header = captured_auth_request.headers['Authorization']
      assert_match(/\ABasic /, auth_header,
                   'Must use HTTP Basic authentication (RFC 6749 §2.3.1)')
      decoded_credentials = Base64.decode64(auth_header.sub('Basic ', ''))
      client_id, client_secret = decoded_credentials.split(':', 2)
      assert_equal 'test_client_id', client_id,
                   'Basic auth username must be client_id (RFC 6749 §2.3.1)'
      assert_equal 'test_client_secret', client_secret,
                   'Basic auth password must be client_secret (RFC 6749 §2.3.1)'
    ensure
      verbose = $VERBOSE
      $VERBOSE = nil
      Net::HTTP::Post.remove_method(:initialize)
      $VERBOSE = verbose
    end
  end

  def test_token_request_uses_origin_form_with_custom_oauth_url
    captured_request_paths = []
    Net::HTTP::Post.define_method(:initialize) do |path, initheader = nil|
      captured_request_paths << path
      super(path, initheader)
    end

    stub_request(:post, 'https://auth.us-east-1.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json)

    begin
      FragmentClient.new('client_id', 'client_secret',
                         oauth_url: 'https://auth.us-east-1.fragment.dev/oauth2/token')

      assert_equal '/oauth2/token', captured_request_paths.first,
                   'Custom oauth_url must also use origin-form request-target (RFC 7230 §5.3.1)'
    ensure
      verbose = $VERBOSE
      $VERBOSE = nil
      Net::HTTP::Post.remove_method(:initialize)
      $VERBOSE = verbose
    end
  end

  def test_explicit_nil_oauth_settings_fall_back_to_the_defaults
    # Both keywords are declared nilable, so nil has to mean "use the default".
    # Asserting it raised nothing is the point: `T.let(oauth_scope, String)` used
    # to turn an explicit nil into a TypeError.
    captured = nil
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return do |request|
        captured = request
        { status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json }
      end

    FragmentClient.new('client_id', 'client_secret', oauth_url: nil, oauth_scope: nil)

    assert_equal 'https://api.fragment.dev/*',
                 URI.decode_www_form(captured.body).to_h['scope']
    assert_equal 'auth.fragment.dev', captured.uri.host
  end

  def test_a_non_http_oauth_url_is_rejected_where_it_is_passed
    # Anything without a request_uri used to get as far as create_token and fail
    # there as a NoMethodError, which says nothing about the argument that caused
    # it. No token request should be attempted at all.
    stub_request(:post, /.*/).to_return(status: 200, body: '{}')

    # WebMock's journal is process-global, and a test class whose teardown
    # shadows the adapter's leaks its requests into it. Only what this test
    # does below is relevant to the assertion at the end.
    WebMock::RequestRegistry.instance.reset!

    {
      'ftp://auth.example.com/token' => /must be an http or https URL/,
      'auth.fragment.dev/oauth2/token' => /must be an http or https URL/,
      # Malformed rather than merely wrong-scheme: this used to escape as a
      # URI::InvalidURIError that never named the argument.
      'not a url at all' => /oauth_url is not a valid URL/
    }.each do |bad, expected|
      error = assert_raises(ArgumentError, "#{bad.inspect} should be rejected") do
        FragmentClient.new('client_id', 'client_secret', oauth_url: bad)
      end
      assert_match expected, error.message
      assert_match(/#{Regexp.escape(bad)}/, error.message)
    end

    assert_not_requested :post, /.*/
  end

  def test_a_plain_http_oauth_url_is_accepted
    # The check is on the scheme family, not on TLS: a local or proxied auth
    # endpoint over http must still work.
    stub_request(:post, 'http://localhost:8080/oauth2/token')
      .to_return(status: 200, body: { access_token: 't', expires_in: 3600 }.to_json)

    FragmentClient.new('client_id', 'client_secret', oauth_url: 'http://localhost:8080/oauth2/token')

    assert_requested :post, 'http://localhost:8080/oauth2/token'
  end

  def test_an_https_oauth_url_is_accepted
    # URI::HTTPS subclasses URI::HTTP, so the check above must not reject it --
    # which is the scheme every real deployment uses.
    stub_request(:post, 'https://auth.eu-west-1.fragment.dev/oauth2/token')
      .to_return(status: 200, body: { access_token: 't', expires_in: 3600 }.to_json)

    FragmentClient.new('client_id', 'client_secret',
                       oauth_url: 'https://auth.eu-west-1.fragment.dev/oauth2/token')

    assert_requested :post, 'https://auth.eu-west-1.fragment.dev/oauth2/token'
  end

  def test_token_request_uses_appendix_b_form_encoding_utf8
    captured_auth_request = nil
    stub_request(:post, 'https://auth.fragment.dev/oauth2/token')
      .to_return do |request|
        captured_auth_request = request
        { status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json }
      end

    client_id = 'client id+special&utf8-umlaut-umlauts-äöü'
    oauth_scope = 'https://api.fragment.dev/read write?x=1&y=2'

    FragmentClient.new(client_id, 'secret', oauth_scope: oauth_scope)

    # RFC 6749 §4.4.2 requires x-www-form-urlencoded per Appendix B (UTF-8).
    body_params = URI.decode_www_form(captured_auth_request.body).to_h
    assert_equal 'client_credentials', body_params['grant_type']
    assert_equal oauth_scope, body_params['scope'],
                 'scope should round-trip via x-www-form-urlencoded UTF-8 encoding'
    assert_equal client_id, body_params['client_id'],
                 'client_id should round-trip via x-www-form-urlencoded UTF-8 encoding'
  end
end
