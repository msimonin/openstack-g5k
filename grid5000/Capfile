require 'bundler/setup'
require 'rubygems'
require 'capistrano'
require 'xp5k'
require 'erb'
require 'colored'

load "config/deploy.rb"

desc 'Automatic deployment'
task :automatic do
 puts "Welcome to automatic deployment".bold.blue
end

after "automatic", "xp5k", "puppetcluster", "openstack", "openstack:bootstrap"
