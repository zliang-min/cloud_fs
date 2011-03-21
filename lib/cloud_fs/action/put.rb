# -*- encoding: utf-8 -*-

require 'base64'

module CloudFS
  module Action
    class PUT < POST

      register_error :BadDigest, 'The Content-MD5 you specified did not match what we received.'

      protected
        def validate_request
          super
          validates_uploaded_file
        end

        def validates_uploaded_file
          halt(:BadDigest) unless
            @env['Content-MD5'].nil? || 
            @env['Content-MD5'] == Base64.encode64(Utils.md5(file))
        end

        def _call
          id = fs.save file, :space => name_space
          response_with 204, HEADER_ID => id
        end

        def resource
          request.path
        end

        def file
          request.body
        end
    end # CloudFS
  end # Dispatcher
end # CloudFS
