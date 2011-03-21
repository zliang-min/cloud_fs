# encoding: utf-8

module Rack
  class ZombieShotgun

    ZOMBIE_AGENTS = [
      /FrontPage/,
      /Microsoft Office Protocol Discovery/,
      /Microsoft Data Access Internet Publishing Provider/
    ].freeze

    ZOMBIE_DIRS = ['_vti_bin','MSOffice','verify-VCNstrict','notified-VCNstrict'].to_set.freeze

    attr_reader :options, :request, :agent

    def initialize(app, options={})
      @app, @options = app, {
        :agents => true,
        :directories => true
      }.merge(options)
    end

    def call(env)
      @agent = env['HTTP_USER_AGENT']
      @request = Rack::Request.new(env)
      zombie_attack? ? head_not_found : @app.call(env)
    end

    private

    def head_not_found
      [404, {"Content-Length" => "0"}, []]
    end

    def zombie_attack?
      zombie_dir_attack? || zombie_agent_attack?
    end

    def zombie_dir_attack?
      path = request.path_info
      options[:directories] && ZOMBIE_DIRS.any? { |dir| path.include?("/#{dir}/") }
    end

    def zombie_agent_attack?
      options[:agents] && agent && ZOMBIE_AGENTS.any? { |za| agent =~ za }
    end

  end
end
