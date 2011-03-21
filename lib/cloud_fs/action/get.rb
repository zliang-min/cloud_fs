# -*- encoding: utf-8 -*-

require 'time'

module CloudFS
  module Action
    class GET < Base
      register_error :InvalidFileId,       'The file id is invalid.'
      register_error :FileNotFound,        'The requested file was not found.', 404
      register_error :InvalidThumbnail,    'Unknow thumbnail format.'
      register_error :OutOfThumbnailRange, 'Thumbnail size was out of range.'
      register_error :ThumbnailNotAllow,   'Thumbnail is not allowed on this file.'

      VALID_THUMBNAILS = [/\A(\d+)\z/, /\A(\d+)x(\d+)\z/].freeze

      protected
        def _call
          file = get_file
          # prepare http-cache relatied headers
          headers = {
            HTTP_CONTENT_MD5 => file['md5'],
            HTTP_ETAG => %("#{file['md5']}"),
            HTTP_CACHE_CONTROL => 'max-age=630720000, public', # 20 years
            HTTP_LAST_MODIFIED => file.upload_date.httpdate
          }
          # conditional GET
          if (match = @env[HTTP_IF_NONE_MATCH])       && match == %("#{file['md5']}") ||
             (modified = @env[HTTP_IF_MODIFIED_SINCE]) && Time.httpdate(modified).utc <= file.upload_date
            [304, headers, []]
          else
            [
              200,
              {
                HTTP_CONTENT_LENGTH => file.file_length.to_s,
                HTTP_CONTENT_TYPE   => file.content_type
              }.update(headers),
              file
            ]
          end
        rescue BSON::InvalidObjectId
          halt :InvalidFileId
        rescue Mongo::GridFileNotFound
          halt :FileNotFound
        rescue TypeError # raised by ImageScience
          halt :ThumbnailNotAllow
        end

        def resource
          @resource ||= File.basename(@env['SCRIPT_NAME'].to_s + @env['PATH_INFO'].to_s)
        end

        def get_file
          id, ext = resource.split '.'
          id, md5 = id.split '-'

          halt :InvalidFileId if id.nil?

          if md5
            md5, thumbnail = md5.split '_'
          else
            id,  thumbnail = id.split '_'
          end

          validates_thumbnail thumbnail if thumbnail

          space = name_space
          file  = fs.find id, :space => space
          halt :FileNotFound if md5 && file['md5'] != md5 || ext && File.extname(file.filename) != ".#{ext}"

          if thumbnail
            halt :ThumbnailNotAllow unless CloudFS.config.thumbnail_allow === file.content_type
            begin
              file = fs.find_or_create_thumbnail id, :size => thumbnail, :space => space
            rescue ThumbnailTooLarge
              # no-op, just return the original file
            end
          end

          file
        end

        def validates_thumbnail(size)
          halt :InvalidThumbnail unless VALID_THUMBNAILS.any? { |exp| exp =~ size }
          sizes = [$1.to_i]
          sizes << $2.to_i if $2
          halt :OutOfThumbnailRange unless sizes.all? { |d| CloudFS.config.thumbnail_size === d }
        end
    end # GET
  end # Dispatcher
end # CloudFS
