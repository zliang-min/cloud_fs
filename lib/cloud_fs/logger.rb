# -*- encoding: utf-8 -*-

require 'logger'

module CloudFS
  class Logger < ::Logger
    def initialize(app, config)
      @app = app

      path = config.log_path || default_log_path
      unless File.file?(path)
        require 'fileutils'
        dir = File.dirname path
        FileUtils.mkdir_p dir unless File.directory?(dir)
        FileUtils.touch path
      end

      case rolling = config.log_rolling
      when Array
        super path, *rolling
      when String
        super path, rolling
      else
        super path
      end
      self.level = self.class.const_get((config.log_level || default_log_level).to_s.upcase)
    end

    def call(env)
      env[ENV_LOGGER] = self
      @app.call(env)
    end

    private
      def default_log_path
        File.expand_path "../../../logs/#{ENV['RACK_ENV'] || 'cloud_fs'}.log", __FILE__
      end

      def default_log_level
        :info
      end
  end
end
