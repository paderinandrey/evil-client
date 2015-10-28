require "logger"

class Evil::Client
  # Sends the request to remote API and processes the response
  #
  # It is responsible for:
  # * sending requests to the server
  # * deserializing a response body
  # * handling error responses
  #
  # @api private
  #
  class Adapter
    # @api private
    class << self
      # @!attribute [rw] logger
      #
      # @return [::Logger, nil] The logger used by all connections
      #
      attr_accessor :logger
    end

    # Initializes the adapter to selected API <specification>
    #
    # @param [Evil::Client::API] api
    #
    # @return [Evil::Client::Adapter]
    #
    def self.for_api(api)
      new(base_url: api.base_url)
    end

    # @!method initialize(options)
    # Initializes the adapter with base_url and optional logger
    #
    # @param [Hash] options
    # @option options [String] :base_url
    # @option options [String] :logger
    # 
    def initialize(base_url:, **options)
      @base_url = base_url
      @logger   = options.fetch(:logger) { self.class.logger }
    end

    # Sends the request to API, handles and returns its response
    #
    # @param [Evil::Client::Request] request
    # @param [Proc] error_handler Custom handler of error responses
    #
    # @return [Object] Deserialized body of a server response
    #
    # @yield block when API responds with error (status 4** or 5**)
    # @yieldparam [HTTP::Message] The raw message from the server
    # @see http://www.rubydoc.info/gems/httpclient/HTTP/Message
    #   Docs for HTTP::Message format
    #
    # @raise [Evil::Client::Errors::ResponseError]
    #   when API responds with error and no block given
    #
    def call(request, &error_handler)
      raw_response = __send__(*request.to_a)
      handle(request, raw_response, &error_handler)
    end

    private

    def connection
      @connection ||= begin
        json_client = JSONClient.new(base_url: @base_url)
        json_client.debug_dev = @logger
        json_client
      end
    end

    def get(uri, params)
      connection.get_content(uri, params)
    end

    def post(uri, params)
      connection.post_content(uri, params)
    end
    alias_method :patch, :post
    alias_method :delete, :post

    def handle(request, raw_response)
      return Helpers.deserialize(raw_response) if raw_response.status < 400
      fail ResponseError.new(request, raw_response) unless block_given?
      yield(raw_response)
    end
  end
end
