class Evil::Client
  # Data structure describing a request to remote server
  #
  # Contains method to return a copy of the request updated with some data
  #
  # @api public
  #
  class Request

    # Initializes request with base url
    #
    # @param [String] base_url
    #
    def initialize(base_url)
      @path = base_url.to_s.sub(%r{/+$}, "")
    end

    # The type of the request
    #
    # @return ["get", "post"]
    #
    attr_reader :type

    # The request path
    #
    # @return [String]
    #
    attr_reader :path

    # The request headers
    #
    # @return [Hash<String, String>]
    #
    def headers
      @headers ||=
        if request_id
          DEFAULT_HEADERS.merge("X-Request-Id" => request_id)
        else
          DEFAULT_HEADERS
        end
    end

    # The request body
    #
    # @return [Hash<String, String>]
    #
    def body
      @body ||= {}
    end

    # The request query
    #
    # @return [Hash<String, String>]
    #
    def query
      @query ||= {}
    end

    # The hash of request parameters
    #
    # @return [Hash]
    #
    def params
      hash = { header: headers }
      hash.update(query: query) unless query.empty?
      hash.update(body: body)   unless body.empty?
      hash
    end

    # Returns a copy of the request with new parts added to the uri
    #
    # @param [#to_s, Array<#to_s>] parts
    #
    # @return [Evil::Client::Request]
    #
    def with_path(*parts)
      paths    = parts.flat_map { |part| part.to_s.split("/").reject(&:empty?) }
      new_path = [path, *paths].join("/")

      update { @path = new_path }
    end

    # Returns a copy of the request with new headers being added
    #
    # @param [Hash<#to_s, #to_s>] values
    #
    # @return [Evil::Client::Request]
    #
    def with_headers(values)
      new_headers = headers.merge(values)
      update { @headers = new_headers }
    end

    # Returns a copy of the request with new values added to its query
    #
    # @param [Hash<#to_s, #to_s>] values
    #
    # @return [Evil::Client::Request]
    #
    def with_query(values)
      new_query = query.merge(values)
      update { @query = new_query }
    end

    # Returns a copy of the request with new values added to its body
    #
    # @param [Hash<#to_s, #to_s>] values
    #
    # @return [Evil::Client::Request]
    #
    def with_body(values)
      new_body = body.merge(values)
      update { @body = new_body }
    end

    # Returns a copy of the request with a type added
    #
    # @param [String] raw_type
    #
    # @return [Evil::Client::Request]
    #
    def with_type(raw_type)
      new_body =
        case raw_type
        when "get"  then {}
        when "post" then body.reject { |key| key == "_method" }
        else body.merge("_method" => raw_type)
        end

      update do
        @type = (raw_type == "get") ? "get" : "post"
        @body = new_body
      end
    end

    # Returns a standard array representation of the request
    #
    # @see [Evil::Client::Adapter#call]
    #
    # @return [Array]
    #
    def to_a
      [type, path, params]
    end

    private

    DEFAULT_HEADERS = {
      "Content-Type" => "application/json; charset=utf-8",
      "Accept"       => "application/json"
    }.freeze

    def request_id
      @request_id ||= RequestID.value
    end

    def update(&block)
      dup.tap { |instance| instance.instance_eval(&block) }
    end
  end
end
