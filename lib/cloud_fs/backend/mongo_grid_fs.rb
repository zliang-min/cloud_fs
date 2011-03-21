# -*- encoding: utf-8 -*-

require 'tempfile'
require 'mongo'

module CloudFS
  module Backend
    class MongoGridFS

      include Mongo

      DEFAULT_OPTIONS = {:space => 'files'.freeze}.freeze

      Grid.class_eval do
        # Initialize a new Grid instance, consisting of a MongoDB database
        # and a filesystem prefix if not using the default.
        #
        # @core gridfs
        #
        # @see GridFileSystem
        def initialize(db, fs_name=DEFAULT_FS_NAME)
          raise MongoArgumentError, "db must be a Mongo::DB." unless db.is_a?(Mongo::DB)

          @db      = db
          @files   = @db["#{fs_name}.files"]
          @chunks  = @db["#{fs_name}.chunks"]
          @fs_name = fs_name

          @chunks.create_index([['files_id', Mongo::ASCENDING], ['n', Mongo::ASCENDING]]) # can't do shard if , :unique => true)
        end
      end

      GridIO.class_eval do
        def each
          while chunk = read(self[:chunk_size])
            # when chunk is nil, that means we reach the end of the file;
            # while chunk is empty, we get an empty file (we will never get a nil).
            # ** NOTE **
            # we cann't do:
            #   yield chunk
            #   break if chunk.empty?
            # since strings are mutable.
            if chunk.empty?
              yield chunk
              break
            else
              yield chunk
            end
          end
        end
      end

      # @param [Hash] options all options which are valid to Mongo::Connection.new will remain the same meaning.
      # @option options [String, Array] ::host MongoDB host, or an array of replica pairs, like: [['pairhost1', 27107], ['pairhost2', 27107]].
      # @option options [Integer] :port MongoDB port. If option :host is an array, :post will be ignored.
      # @option options [String] db database name, defaults 'files'.
      def initialize(app, config)
        @app = app
        options = config.mongo || {}
        @connection =
          if Array === host = options[:host]
            Connection.paird host, options
          else
            Connection.new host, options[:port], options
          end
        @db = @connection[options[:db] || 'files']
      end

      # @raise [Mongo::ConnectionFailure] if unable to connect to any host or port
      def reconnect!
        @connection.connect_to_master
      end

      def call(env)
        env[ENV_BACKEND] = self
        @logger = env[ENV_LOGGER]
        @app.call(env)
      end

      # @param [File] file
      # @param [Hash] options
      # @option options [String, Symbol] :space space in which the file is going to be stored. Different space means different collection in mongo.
      # @option options [String] :filename
      # @option options [String] :watermark the ObjectId of the watermark image file.
      # @option options [String] :resize_to
      def save(file, options = {})
        standardlize_options! options
        save_with_resize file, options
      end

      # @private
      def save_with_resize(file, options)
        (resize = options.delete(:resize_to)) &&
          Utils.resize_image(file, resize) { |image| save_with_watermark(image, options) } ||
          save_with_watermark(file, options)
      end
      private :save_with_resize

      # @private
      def save_with_watermark(file, options)
        if watermark = options.delete(:watermark)
          begin
            watermark = find(watermark, options)
            Utils.watermark(file, watermark)  { |image| _save(image, options) }
          rescue Mongo::GridFileNotFound # watermark is not found. should I response with an error?
            _save file, options
          end
        else
          _save file, options
        end
      end
      private :save_with_watermark

      # @private
      def _save(file, options)
        # Should grids be cached ?
        grid = Grid.new(@db, options.delete(:space))
        grid.get grid.put(
          file.respond_to?(:to_blob) && file.to_blob || file, options
        )
      end
      private :_save

      def find(id, options = {})
        standardlize_options! options
        GridIO.new @db["#{options[:space]}.files"], @db["#{options[:space]}.chunks"], nil, 'r', :query => {'_id' => bson_object_id_for(id)}
      end

      def delete(id, options = {})
        standardlize_options! options
        id = bson_object_id_for id
        @db["#{options[:space]}.files"].remove '_id' => id
        @db["#{options[:space]}.chunks"].remove 'files_id' => id
      end

      def find_or_create_thumbnail(id, options = {})
        standardlize_options! options
        space       = options[:space]
        id          = bson_object_id_for id
        size        = options[:size].to_s
        find_thumbnail space, id, size
      rescue Mongo::GridFileNotFound
        create_thumbnail space, id, size
      end

      def find_thumbnail(space, id, size)
        GridIO.new @db["#{space}.thumbnails.files"], @db["#{space}.thumbnails.chunks"], nil, 'r', :query => {'original_file_id' => id, 'size' => size}
      end
      private :find_thumbnail

      def create_thumbnail(space, id, size)
        original_file = GridIO.new @db["#{space}.files"], @db["#{space}.chunks"], nil, 'r', :query => {'_id' => id}, :fs_name => space
        file = GridIO.new(@db["#{space}.thumbnails.files"], @db["#{space}.thumbnails.chunks"], nil, 'w',
                          :fs_name => "#{space}.thumbnails", :content_type => original_file[:content_type])
        file['size'] = size
        file['original_file_id'] = original_file.files_id
        if Utils.resize_image(original_file.read, size) { |image| file.write image.to_blob }
          file.close
          find_thumbnail space, file['original_file_id'], size
        else
          raise ThumbnailTooLarge
        end
      end
      private :create_thumbnail

      def standardlize_options!(options)
        DEFAULT_OPTIONS.each { |option, value| options[option] ||= value }
      end
      private :standardlize_options!

      def bson_object_id_for(id)
        id.is_a?(BSON::ObjectId) ? id : BSON::ObjectId.from_string(id)
      end
      private :bson_object_id_for

    end # MongoGridFS
  end # Backend
end # CloudFS
