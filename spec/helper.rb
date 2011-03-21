require File.join(File.dirname(__FILE__), '../boot')

Bundler.require :default, :test

require File.join(File.dirname(__FILE__), '../boot')

Dir[File.expand_path('../helpers/*.rb', __FILE__)].each { |helper_rb| require File.join(File.dirname(helper_rb), File.basename(helper_rb, '.rb')) }

module Rack::Test::SpecHelper
  def app
    CloudFS.build_app
  end
end

Spec::Runner.configure do |config|
  config.include Rack::Test::SpecHelper, Rack::Test::Methods
end
