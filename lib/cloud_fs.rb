# -*- encoding: utf-8 -*-

require 'rack'

module CloudFS

  autoload :Action,        'cloud_fs/action'
  autoload :Backend,       'cloud_fs/backend'
  autoload :Configuration, 'cloud_fs/configuration'
  autoload :Dispatcher,    'cloud_fs/dispatcher'
  autoload :Logger,        'cloud_fs/logger'
  autoload :Utils,         'cloud_fs/utils'

  ThumbnailTooLarge = Class.new RuntimeError

  HTTP_GET  = 'GET'.freeze
  HTTP_PUT  = 'PUT'.freeze
  HTTP_POST = 'POST'.freeze
  HTTP_HEAD = 'HEAD'.freeze

  HTTP_CACHE_CONTROL     = 'Cache-Control'.freeze
  HTTP_CONTENT_LENGTH    = 'Content-Length'.freeze
  HTTP_CONTENT_MD5       = 'Content-MD5'.freeze
  HTTP_CONTENT_TYPE      = 'Content-Type'.freeze
  HTTP_ETAG              = 'ETag'.freeze
  HTTP_LAST_MODIFIED     = 'Last-Modified'.freeze
  HTTP_IF_MODIFIED_SINCE = 'HTTP_IF_MODIFIED_SINCE'.freeze
  HTTP_IF_NONE_MATCH     = 'HTTP_IF_NONE_MATCH'.freeze

  MIME_XML  = 'text/xml'.freeze
  MIME_HTML = 'text/html'.freeze

  HEADER_ID = 'x-cloud-fs-id'.freeze

  ENV_BACKEND = 'cloud_fs.backend'.freeze
  ENV_LOGGER  = 'rack.logger'.freeze

  C_file = 'file'.freeze

  class << self
    attr_reader :config

    def env
      ENV['RACK_ENV'] || 'development'
    end

    def root
      File.expand_path '../..', __FILE__
    end

    def public_directory
      File.join root, 'public'
    end

    def config_file
      File.join root, 'config', env, 'environment.rb'
    end

    def build_app
      load_config_file do |config|
        Rack::Builder.app do
          require 'rack/zombie_shotgun'

          use Rack::ZombieShotgun
          use CloudFS::Logger, config
          use CloudFS::Backend::MongoGridFS, config

          run Rack::Cascade.new [
            Rack::File.new(CloudFS.public_directory),
            CloudFS::Dispatcher.new
          ]
        end
      end
    end
    
    private

    def load_config_file
      @config = Configuration.load_file config_file
      if block_given?
        yield @config
      end
    end
  end
end
