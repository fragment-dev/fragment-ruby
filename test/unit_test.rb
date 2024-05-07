# frozen_string_literal: true
# typed: true

require 'minitest/autorun'
require 'webmock/minitest'
require 'fragment_client'

class UnitTest < Minitest::Test
  include WebMock::API

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
end
