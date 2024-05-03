# typed: false
# frozen_string_literal: true

require 'faraday'
require 'faraday/net_http'
require 'json'
require 'graphql/client'
require 'graphql/client/http'
require 'sorbet-runtime'
require 'uri'

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
  extend T::Sig

  sig do
    params(client_id: String, client_secret: String, extra_queries_filename: T.nilable(String),
           execute: T.nilable(GraphQL::Client::HTTP), api_url: T.nilable(String),
           oauth_url: T.nilable(String), oauth_scope: T.nilable(String)).void
  end
  def initialize(client_id, client_secret, extra_queries_filename: nil, execute: nil, api_url: nil,
                 oauth_url: 'https://auth.fragment.dev/oauth2/token', oauth_scope: 'https://api.fragment.dev/*')
    @oauth_scope = T.let(oauth_scope, String)
    @oauth_url = T.let(URI.parse(oauth_url), URI)
    @client_id = T.let(client_id, String)
    @client_secret = T.let(client_secret, String)

    execute ||= api_url ? FragmentGraphQl::CustomHTTP.new(URI.parse(api_url)) : FragmentGraphQl::HTTP
    @execute = T.let(execute, GraphQL::Client::HTTP)

    @client = T.let(GraphQL::Client.new(schema: FragmentGraphQl::FragmentSchema, execute: @execute), GraphQL::Client)
    @conn = T.let(create_conn, Faraday::Connection)
    # TODO: the token may need to be refreshed if the client is around for a long time
    @token = T.let(create_token, String)

    define_method_from_queries(FragmentGraphQl::FragmentQueries)
    return if extra_queries_filename.nil?

    queries = @client.parse(
      File.read(extra_queries_filename)
    )
    define_method_from_queries(queries)
  end

  sig { params(query: T.untyped, variables: T.untyped).returns(T.untyped) }
  def query(query, variables)
    @client.query(query, variables: variables, context: { access_token: @token })
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

  sig { returns(Faraday::Connection) }
  def create_conn
    T.let(Faraday.new(@oauth_url) do |f|
      f.request :url_encoded
      f.request :authorization, :basic, @client_id, @client_secret
      f.adapter :net_http
      f.response :raise_error
    end, Faraday::Connection)
  end

  sig { returns(String) }
  def create_token
    begin
      response = @conn.post do |req|
        req.body = format('grant_type=client_credentials&scope=%<scope>s&client_id=%<id>s', scope: @oauth_scope,
                                                                                            id: @client_id)
      end
    rescue Faraday::ClientError => e
      raise StandardError, format("oauth Authentication failed: '%s'", e.to_s)
    end
    T.let(JSON.parse(response.body)['access_token'], String)
  end
end
