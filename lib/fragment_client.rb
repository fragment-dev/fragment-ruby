# typed: false
# frozen_string_literal: true

require 'json'
require 'graphql/client'
require 'graphql/client/http'
require 'sorbet-runtime'
require 'uri'
require 'net/http'

# A support module for the client
module FragmentGraphQl
  extend T::Sig

  CustomHTTP = Class.new(GraphQL::Client::HTTP) do
    extend T::Sig
    sig { params(context: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
    def headers(context)
      { 'Authorization' => format('Bearer %s', context[:access_token]) }
    end
  end

  HTTP = T.let(CustomHTTP.new('https://api.fragment.dev/graphql'), GraphQL::Client::HTTP)

  FragmentSchema = T.let(GraphQL::Client.load_schema("#{__dir__}/fragment.schema.json"), T.untyped)

  Client = T.let(GraphQL::Client.new(schema: FragmentSchema, execute: HTTP), GraphQL::Client)

  FragmentQueries = T.let(Client.parse(
                            File.read("#{__dir__}/queries.graphql")
                          ), T.untyped)
end

# A client for Fragment
class FragmentClient
  # A token for the client with an expiry time
  class Token < T::Struct
    const :token, String
    const :expires_at, Time
  end

  extend T::Sig

  sig do
    params(client_id: String, client_secret: String, extra_queries_filename: T.nilable(String),
           api_url: T.nilable(String), oauth_url: T.nilable(String), oauth_scope: T.nilable(String)).void
  end
  def initialize(client_id, client_secret, extra_queries_filename: nil, api_url: nil,
                 oauth_url: 'https://auth.fragment.dev/oauth2/token', oauth_scope: 'https://api.fragment.dev/*')
    @oauth_scope = T.let(oauth_scope, String)
    @oauth_url = T.let(URI.parse(oauth_url), URI)
    @client_id = T.let(client_id, String)
    @client_secret = T.let(client_secret, String)

    execute = api_url ? FragmentGraphQl::CustomHTTP.new(URI.parse(api_url.to_s)) : FragmentGraphQl::HTTP
    @execute = T.let(execute, GraphQL::Client::HTTP)

    @client = T.let(GraphQL::Client.new(schema: FragmentGraphQl::FragmentSchema, execute: @execute), GraphQL::Client)
    @token = T.let(create_token, Token)

    define_method_from_queries(FragmentGraphQl::FragmentQueries)
    return if extra_queries_filename.nil?

    queries = @client.parse(
      File.read(extra_queries_filename)
    )
    define_method_from_queries(queries)
  end

  sig { params(query: T.untyped, variables: T.untyped).returns(T.untyped) }
  def query(query, variables)
    expiry_time_skew = 120
    @token = create_token if Time.now > @token.expires_at - expiry_time_skew
    puts query
    @client.query(query, variables: variables, context: { access_token: @token.token })
  end

  private

  def define_method_from_queries(queries)
    queries.constants.each do |qry|
      name = qry.to_s.gsub(/[a-z]([A-Z])/) do |m|
        format('%<lower>s_%<upper>s', lower: m[0], upper: m[1].downcase)
      end.gsub(/^[A-Z]/, &:downcase)
      define_singleton_method(name) do |v|
        query(queries.const_get(qry), v)
      end
    end
  end

  sig { returns(Token) }
  def create_token
    uri = URI.parse(@oauth_url.to_s)
    post = Net::HTTP::Post.new(uri)
    post.basic_auth(@client_id, @client_secret)
    post.body = format('grant_type=client_credentials&scope=%<scope>s&client_id=%<id>s', scope: @oauth_scope,
                                                                                         id: @client_id)

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      response = http.request(post)

      case response
      when Net::HTTPSuccess
        # Parse the response body
        body = JSON.parse(response.body)
        Token.new(
          token: T.let(body['access_token'], String),
          expires_at: Time.now + T.let(body['expires_in'], Integer)
        )
      else
        raise StandardError, format("oauth Authentication failed: '%s'", response.body)
      end
    rescue StandardError => e
      raise StandardError, format("oauth Authentication failed: '%s'", e.to_s)
    end
  end
end
