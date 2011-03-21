# -*- encoding: utf-8 -*-

module CloudFS
  class Dispatcher

    def initialize
      @request_counter = 0
    end

    def call(env)
      @request_counter += 1
      if @request_counter > 200
        GC.start
        @request_counter = 0
      end

      Action.const_get(env["REQUEST_METHOD"]).new.call(env)
    rescue NameError
      allowed_methods = Rack::Request.new(env).path == '/' ? ['POST'] : ['GET']
      [405, {Allow: allowed_methods.join(', ')}, ['']]
    rescue Exception
      [500, {HTTP_CONTENT_TYPE => 'text/plain', HTTP_CONTENT_LENGTH => $!.to_s.bytesize.to_s}, [$!.to_s]]
    end
  end # Dispatcher
end # CloudFS
