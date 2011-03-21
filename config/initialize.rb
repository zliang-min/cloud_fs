begin
  gem 'bundler', '~> 1.0.7'
  require 'bundler'
rescue LoadError
  require 'rubygems'
  gem 'bundler', '~> 1.0.7'
  require 'bundler'
end

Bundler.setup :default

$:.unshift File.expand_path('../../lib', __FILE__)

require 'cloud_fs'
