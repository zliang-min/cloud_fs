require File.expand_path('../config/initialize', __FILE__)

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
  use Rack::Reloader
else
  require 'hoptoad_notifier'

  HoptoadNotifier.configure do |config|
    config.api_key = '94a4e5283f7bd7a473bb457b36993953'
  end

  use HoptoadNotifier::Rack
end

run CloudFS.build_app
