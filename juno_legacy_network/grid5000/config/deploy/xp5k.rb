require 'bundler/setup'
require 'rubygems'
require 'xp5k'
require 'erb'

# Load ./xp.conf file
#
XP5K::Config.load

# Capistrano variables
#
# sets the gateway if required in the xp.conf
set :gateway, XP5K::Config[:gateway] if XP5K::Config[:gateway]
# fall back to default rsa private key in case of missing parameter
XP5K::Config[:private_key] ||= File.join(ENV["HOME"], ".ssh", "id_rsa")
ssh_options[:keys]= [XP5K::Config[:private_key]]

# Defaults configuration
#
XP5K::Config[:jobname]    ||= 'openstack'
XP5K::Config[:site]       ||= 'toulouse'
XP5K::Config[:walltime]   ||= '1:00:00'
XP5K::Config[:cluster]    ||= ''
XP5K::Config[:vlantype]   ||= 'kavlan'
XP5K::Config[:nodes]      ||= '3'
XP5K::Config[:ssh_public] ||= File.join(ENV["HOME"], ".ssh", "id_rsa.pub")
XP5K::Config[:images]     ||= []
XP5K::Config[:computes]   ||= 1


cluster = "and cluster='" + XP5K::Config[:cluster] + "'" if !XP5K::Config[:cluster].empty?
nodes = 2 + XP5K::Config[:computes].to_i
$myxp = XP5K::XP.new(:logger => logger)

$myxp.define_job({
  :resources  => ["{type='#{XP5K::Config[:vlantype]}'}/vlan=1, {virtual!='none' #{cluster}}/nodes=#{nodes}, walltime=#{XP5K::Config[:walltime]}"],
  :site       => "#{XP5K::Config[:site]}",
  :retry      => true,
  :goal       => "100%",
  :types      => ["deploy"],
  :name       => "#{XP5K::Config[:jobname]}" ,
  :roles      =>  [
    XP5K::Role.new({ :name => 'puppet', :size => 1 }),
    XP5K::Role.new({ :name => 'controller', :size => 1 }),
    XP5K::Role.new({ :name => 'compute', :size => XP5K::Config[:computes] })
  ],
  :command    => "sleep 206400"
})

$myxp.define_deployment({
  :site           => XP5K::Config[:site],
  :environment    => "ubuntu-x64-1404",
  :roles          => %w(puppet controller compute),
  :vlan_from_job  => XP5K::Config[:jobname],
  :key            => File.read(XP5K::Config[:ssh_public]), 
})

load "config/deploy/xp5k_common_tasks.rb"



