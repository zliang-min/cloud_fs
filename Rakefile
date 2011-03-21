require 'rubygems'
require 'bundler'
Bundler.setup :default, :test
require 'spec/rake/spectask'

desc "Default task: spec."
task :default => :spec

Spec::Rake::SpecTask.new do |t|
 t.libs << File.expand_path('../lib', __FILE__)
end

desc 'Generate a secret key.'
task :secret do
  require 'securerandom'
  puts 'Below is new secret key, please copy it to your config.rb.'
  puts SecureRandom.hex(64)
end
