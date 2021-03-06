module Wrappi
  class Request
    class Template
      attr_reader :endpoint
      def initialize(endpoint)
        @endpoint = endpoint
      end

      def client
        endpoint.client
      end

      def params
        endpoint.consummated_params
      end

      def url
        endpoint.url
      end

      def verb
        endpoint.verb
      end

      def http
        h = HTTP.timeout(client.timeout)
                .headers(endpoint.headers)
        h = h.follow() if endpoint.follow_redirects # TODO: add strict mode
        h = h.basic_auth(endpoint.basic_auth) if endpoint.basic_auth
        h
      end

      def call
        raise NotImplementedError
      end
    end
  end
end
