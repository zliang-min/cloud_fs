# -*- encoding: utf-8 -*-

module CloudFS
  module Action
    class Base

      NAMESPACE_PATTERN = /\A(?:.+\.)?([^.]+)\.51hejia\.(?:com|net)\z/.freeze

      @@errors ||= {}
      class << self
        def errors; @@errors end

        def register_error(code, message, status = 400)
          errors[code] = {:code => code.to_s, :message => message, :status => status}
        end
        protected :register_error
      end

      # Serve a request. Subclasses should implement at least #_call, which returns a valid rack response.
      # Also, subclasses could implement #validate_request, which validates the incoming request with the throw-catch machanism.
      def call(env)
        @env = env
        response =
          catch(:halt) do
            validate_request
            _call
          end
        response.is_a?(Array) ? response : error!(response)
      rescue
        logger.error "#{$!} :\n#{$@.join "\n"}"
        fs.reconnect! rescue nil if Mongo::ConnectionFailure === $!
        response_with 500
      end

      protected
        # @abstract
        def validate_request; end

        # @abstract
        def _call; response_with 204 end

        # @abstract
        def resource; end

        def backend
          @env[ENV_BACKEND]
        end
        alias fs backend

        def logger
          @env[ENV_LOGGER]
        end

        def request
          @request ||= Rack::Request.new @env
        end

        def params
          @params ||= request.params
        end

        # @param [optional, Integer] status response status code, defaults 200
        # @param [optional, Hash] headers response headers. By default, it has a Content-Type values text/html.
        # @param [optional, String, Array<#to_s>] body response body.
        # @yield response body, if the body block is represented, the body param will be ignored.
        # @return [Array] a rack response array.
        def response_with(*args)
          status, headers, body = args.first.is_a?(Integer) ? args : [200, *args]
          headers ||= {}
          if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
            body = []
          else
            headers[HTTP_CONTENT_TYPE] ||= MIME_HTML
            body = yield if block_given?
            body ||= []
            body.respond_to?(:each) or body = [body]
            headers[HTTP_CONTENT_LENGTH] ||= body.inject(0) { |sum, chunk| sum += Rack::Utils.bytesize chunk.to_s }.to_s
          end
          [status, headers, body]
        end

        def halt(error_id); throw :halt, error_id end

        # Return an error response.
        # @param [Integer] error_id error code, 
        # @return [Array] a rack response array.
        def error!(error_id)
          error = self.class.errors[error_id.to_sym]
          response_with error[:status], {HTTP_CONTENT_TYPE => MIME_XML}, error_xml(error)
        end

        # Return an error xml response body.
        def error_xml(options = {})
<<_XML_
<?xml version="1.0" encoding="UTF-8"?>
<error>
  <code>#{options[:code]}</code>
  <message>#{options[:message]}</message>
  <resource>#{resource}</resource>
</error>
_XML_
        end

        def host_with_port
          if forwarded = @env["HTTP_X_FORWARDED_HOST"]
            forwarded.split(/,\s?/).last
          else
            @env['HTTP_HOST'] || "#{@env['SERVER_NAME'] || @env['SERVER_ADDR']}:#{@env['SERVER_PORT']}"
          end
        end

        def host
          # Remove port number.
          host_with_port.to_s.gsub(/:\d+\z/, '')
        end

        def name_space
          host =~ NAMESPACE_PATTERN && $1
        end
    end # Base
  end # Action
end # CloudFS
