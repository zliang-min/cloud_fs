# -*- encoding: utf-8 -*-

module CloudFS
  module Action
    class POST < Base
      # params['file'] is a Hash, its keys include:
      #   :filename: the name of the uploaded file
      #   :type:     mime type of the uploaded file
      #   :name:     parameter name
      #   :tempfile: a File instance
      #   :head:     request headers

      register_error :InvalidArgument, 'Uploaded file was not supplied.'

      protected
        def validate_request
          halt(:InvalidArgument) if file.nil?
        end

        def _call
          saved_file = fs.save file, :filename  => resource,
                                     :space     => name_space,
                                     :resize_to => resize,
                                     :watermark => watermark
          response_with HTTP_CONTENT_TYPE => MIME_XML, HTTP_ETAG => saved_file['md5'] do <<_XML_
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <id>#{saved_file.files_id}</id>
  <md5>#{saved_file['md5']}</md5>
  <resource>#{resource}</resource>
</response>
_XML_
          end
        end

        def resource
          params[C_file] && params[C_file][:filename]
        end

        def file
          params[C_file] && params[C_file][:tempfile]
        end

        def resize
          params['resize']
        end

        def watermark
          params['watermark']
        end
    end
  end
end
