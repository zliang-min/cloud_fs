# -*- encoding: utf-8 -*-

require 'openssl'

module CloudFS
  class Authentication
    def initialize(app, config)
      @app = app
      @mount_point = config.auth_path || default_mount_point
      @secret = config.secret
      fail 'Please specify your secret key in the config.rb .' unless @secret
    end

    def call(env)
      path = env['SCRIPT_NAME'].to_s + env['PATH_INFO'].to_s
      if path == @mount_point
        token = generate_token
        [200, {HTTP_CONTENT_TYPE => 'text/plain', HTTP_CONTENT_LENGTH => Rack::Utils.bytesize(token).to_s}, [token]]
      else
        env[AUTH] = self
        @app.call(env)
      end
    end

    def generate_token
      token = BSON::ObjectId.new.to_s
      enc = OpenSSL::Cipher::DES.new
      enc.encrypt
      enc.pkcs5_keyivgen @secret
      Base64.encode64(enc.update(token) + enc.final).inspect
=begin
      dec = OpenSSL::Cipher::DES.new
      dec.decrypt
      dec.pkcs5_keyivgen(pass)
      p a = dec.update(s)
      p b = dec.final
      p a + b 
=end
    end
    private :generate_token

    def default_mount_point
      '/token'
    end
    private :default_mount_point
  end
end
