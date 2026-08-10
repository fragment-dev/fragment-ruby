# typed: true
# frozen_string_literal: true

require 'json'
require 'graphql/client'
require 'graphql/client/http'
require 'logger'
require 'sorbet-runtime'
require 'uri'
require 'net/http'
require 'fragment_client/version'
module GraphQL
  module StaticValidation
    # Fragment's `parameters` is a `JSON` scalar, and graphql-ruby rejects an
    # inline object literal for a scalar. This accepts one for the JSON-shaped
    # scalars so that the per-entry-type operations a Schema generates parse at
    # all.
    class LiteralValidator
      alias recursive_validate_old recursively_validate
      def recursively_validate(ast_value, type)
        res = catch(:invalid) do
          recursive_validate_old(ast_value, type)
        end
        if !res.valid? && type.kind.scalar? && ast_value.is_a?(GraphQL::Language::Nodes::InputObject)
          maybe_raise_if_invalid(ast_value) do
            %w[JSON JSONObject Any].include?(type.graphql_name) ? @valid_response : @invalid_response
          end
        else
          res
        end
      end
    end
  end
end

# A support module for the client
module FragmentGraphQl
  VERSION = FragmentSDK::VERSION
  extend T::Sig

  CustomHTTP = Class.new(GraphQL::Client::HTTP) do
    extend T::Sig
    sig { params(context: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
    def headers(context)
      { 'Authorization' => format('Bearer %s', context[:access_token]),
        'X-Fragment-Client' => format('ruby-client@%s', FragmentGraphQl::VERSION) }
    end
  end

  HTTP = T.let(CustomHTTP.new('https://api.fragment.dev/graphql'), GraphQL::Client::HTTP)

  FragmentSchema = T.let(GraphQL::Client.load_schema("#{__dir__}/fragment.schema.json"), T.untyped)

  # Create a custom client class for Fragment-specific behavior
  class CustomClient < GraphQL::Client
    # Names anonymous-module operation definitions predictably, so the operation
    # name sent to the API does not embed a memory address.
    class Definition < GraphQL::Client::Definition
      def definition_name
        super.gsub(/#<Module.*>/, 'FragmentGraphQl__Dynamic')
      end
    end

    # Add this method to allow creating new instances
    def self.new(schema:, execute:)
      super(schema: schema, execute: execute)
    end
  end

  # Use our custom client instead of the base GraphQL::Client
  Client = T.let(CustomClient.new(schema: FragmentSchema, execute: HTTP), CustomClient)

  def self.parse_queries(filename)
    file_text = File.read(filename)
    Client.parse(file_text)
  end

  FragmentQueries = T.let(parse_queries("#{__dir__}/queries.graphql"), T.untyped)
end

# A client for Fragment
class FragmentClient
  # A token for the client with an expiry time
  class Token < T::Struct
    const :token, String
    const :expires_at, Time
  end

  extend T::Sig

  DEFAULT_OAUTH_URL = 'https://auth.fragment.dev/oauth2/token'
  DEFAULT_OAUTH_SCOPE = 'https://api.fragment.dev/*'

  sig do
    params(client_id: String, client_secret: String, extra_queries_filenames: T.nilable(T::Array[String]),
           api_url: T.nilable(String), oauth_url: T.nilable(String), oauth_scope: T.nilable(String)).void
  end

  def initialize(client_id, client_secret, extra_queries_filenames: nil, api_url: nil,
                 oauth_url: DEFAULT_OAUTH_URL, oauth_scope: DEFAULT_OAUTH_SCOPE)
    # These accept nil, so nil has to mean the default rather than being asserted
    # away -- passing `oauth_scope: nil` used to raise a TypeError from `T.let`.
    @oauth_scope = T.let(oauth_scope || DEFAULT_OAUTH_SCOPE, String)
    @oauth_url = T.let(parse_oauth_url(oauth_url || DEFAULT_OAUTH_URL), URI::HTTP)
    @client_id = T.let(client_id, String)
    @client_secret = T.let(client_secret, String)

    execute = api_url ? FragmentGraphQl::CustomHTTP.new(URI.parse(api_url).to_s) : FragmentGraphQl::HTTP
    @execute = T.let(execute, GraphQL::Client::HTTP)

    @client = T.let(
      FragmentGraphQl::CustomClient.new(
        schema: FragmentGraphQl::FragmentSchema,
        execute: @execute
      ),
      FragmentGraphQl::CustomClient
    )
    @token = T.let(create_token, Token)

    define_method_from_queries(FragmentGraphQl::FragmentQueries)
    return if extra_queries_filenames.nil?

    extra_queries_filenames.each do |filename|
      queries = T.let(FragmentGraphQl.parse_queries(filename), T.untyped)
      define_method_from_queries(queries)
    end
  end

  # Move these error class definitions up, before the query method
  class ResponseError < GraphQL::Client::Error; end
  class NetworkError < GraphQL::Client::Error; end
  class AuthenticationError < StandardError; end
  class TokenExpiredError < StandardError; end

  sig { params(query: T.untyped, variables: T.untyped).returns(T.untyped) }
  def query(query, variables)
    refresh_token_if_needed
    @client.query(query, variables: variables, context: { access_token: @token.token })
  end

  private

  def define_method_from_queries(queries)
    queries.constants.each do |qry|
      name = qry.to_s.gsub(/[a-z]([A-Z])/) do |m|
        format('%<lower>s_%<upper>s', lower: m[0], upper: m[1].downcase)
      end.gsub(/^[A-Z]/, &:downcase)

      # Get the original query
      original_query = queries.const_get(qry)

      # Create a monkey-patched version of the definition_node for this specific instance
      # This avoids changing the class type while still modifying the behavior
      if original_query.respond_to?(:definition_node)
        definition_node = original_query.definition_node

        # Only patch once to avoid infinite recursion
        unless definition_node.singleton_class.method_defined?(:original_name)
          # Store the original method
          definition_node.singleton_class.send(:alias_method, :original_name, :name)

          # Define the new method that uses the stored original method
          definition_node.singleton_class.send(:define_method, :name) do
            # The block runs on the definition node, not on the client; Sorbet
            # reads its `self` from the enclosing scope.
            T.bind(self, T.untyped)
            original_name.gsub(/#<Module.*?>/, 'FragmentGraphQl__Dynamic__Custom')
          end
        end
      end

      # Define the method with the original query (which now has patched behavior)
      define_singleton_method(name) do |v|
        query(original_query, v)
      end
    end
  end

  # Reject an unusable `oauth_url` where it is passed.
  #
  # Two failures used to surface far from their cause: a non-HTTP URL reached
  # {create_token} and died there as a NoMethodError on `request_uri`, and a
  # malformed one raised `URI::InvalidURIError` from inside `uri`, neither
  # mentioning the argument responsible. Both are one ArgumentError now.
  sig { params(oauth_url: String).returns(URI::HTTP) }
  def parse_oauth_url(oauth_url)
    parsed = begin
      URI.parse(oauth_url)
    rescue URI::InvalidURIError => e
      raise ArgumentError, "oauth_url is not a valid URL (#{e.message}), got #{oauth_url.inspect}"
    end
    # URI::HTTPS subclasses URI::HTTP, so this accepts both.
    return parsed if parsed.is_a?(URI::HTTP)

    raise ArgumentError, "oauth_url must be an http or https URL, got #{oauth_url.inspect}"
  end

  sig { returns(Token) }
  def create_token
    uri = @oauth_url
    post = Net::HTTP::Post.new(uri.request_uri)
    post.basic_auth(@client_id, @client_secret)
    post.content_type = 'application/x-www-form-urlencoded'
    post.body = URI.encode_www_form(
      grant_type: 'client_credentials',
      scope: @oauth_scope,
      client_id: @client_id
    )

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      response = http.request(post)

      case response
      when Net::HTTPSuccess
        body = JSON.parse(response.body)
        Token.new(
          token: T.let(body['access_token'], String),
          expires_at: Time.now + T.let(body['expires_in'], Integer)
        )
      when Net::HTTPUnauthorized
        raise AuthenticationError, "Invalid credentials: #{response.body}"
      else
        raise AuthenticationError, "Authentication failed (#{response.code}): #{response.body}"
      end
    rescue JSON::ParserError => e
      raise AuthenticationError, "Invalid response format: #{e.message}"
    rescue StandardError => e
      raise AuthenticationError, "Authentication failed: #{e.message}"
    end
  end

  # Process-wide settings, set with {FragmentClient.configure}.
  class Configuration
    extend T::Sig

    sig { returns(Integer) }
    attr_accessor :token_expiry_buffer

    sig { returns(Logger) }
    attr_accessor :logger

    sig { void }
    def initialize
      @token_expiry_buffer = T.let(120, Integer)
      @logger = T.let(Logger.new($stdout), Logger)
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def configuration
      @configuration ||= Configuration.new
    end

    sig { params(blk: T.proc.params(config: Configuration).void).void }
    def configure(&blk)
      blk.call(configuration)
    end
  end

  sig { returns(Logger) }
  def logger
    self.class.configuration.logger
  end

  sig { void }
  def refresh_token_if_needed
    return unless token_expired?

    @token = create_token
  end

  sig { returns(T::Boolean) }
  def token_expired?
    Time.now > @token.expires_at - self.class.configuration.token_expiry_buffer
  end
end
