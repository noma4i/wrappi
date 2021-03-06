module Wrappi
  # Wrapper around HTTP::Response
  # check documentation at:
  # https://github.com/httprb/http/wiki/Response-Handling
  class Response

    attr_reader :block, :endpoint_klass
    def initialize(endpoint_klass, &block)
      @endpoint_klass = endpoint_klass
      @block = block
    end

    def request
      @request ||= block.call
      # raise controlled errors
    end
    alias_method :call, :request

    def called?
      !!@request
    end

    def body
      @body ||= parse
    end

    def success?
      @success ||= endpoint_klass.success?(request)
    end

    def error?
      !success?
    end

    def raw_body
      @raw_body ||= request.to_s
    end

    def uri
      request.uri.to_s
    end

    def status
      request.code
    end
    alias_method :status_code, :status

    def to_h
      @to_h ||= {
        raw_body: raw_body,
        code: code,
        uri: uri,
        success: success?
      }
    end

    def parse
      request.parse
    rescue
      json_parse
    end
    
    def json_parse
      JSON.parse(raw_body)
    rescue
      raw_body
    end

    def method_missing(method_name, *arguments, &block)
      if request.respond_to?(method_name)
        request.send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      request.respond_to?(method_name) || super
    end
  end
end
