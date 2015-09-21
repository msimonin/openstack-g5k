# Common class for nova installation
# Private, and should not be used on its own
# usage: include from controller, declare from worker
# This is to handle dependency
# depends on openstack::profile::base having been added to a node
class openstackg5k::common::nova {

   
  $management_network = $::openstack::config::network_management
  $management_address = ip_for_network($management_network)

  $storage_management_address = $::openstack::config::storage_address_management
  $controller_management_address = $::openstack::config::controller_address_management

  $user                = $::openstack::config::mysql_user_nova
  $pass                = $::openstack::config::mysql_pass_nova
  $database_connection = "mysql://${user}:${pass}@${controller_management_address}/nova"

  class { '::nova':
    database_connection => $database_connection,
    glance_api_servers  => join($::openstack::config::glance_api_servers, ','),
    memcached_servers   => ["${controller_management_address}:11211"],
    rabbit_hosts        => $::openstack::config::rabbitmq_hosts,
    rabbit_userid       => $::openstack::config::rabbitmq_user,
    rabbit_password     => $::openstack::config::rabbitmq_password,
    debug               => $::openstack::config::debug,
    verbose             => $::openstack::config::verbose,
    mysql_module        => '2.2',
  }

  /* handle specific nova parameters here
  some of these parameters are now used by neutron 
  but this isn't what we want here (some others are in the hiera file nova.yaml)
  */
  nova_config { 'DEFAULT/default_floating_pool': value => 'public' }
  nova_config { 'DEFAULT/network_api_class': value => 'nova.network.api.API' }
  nova_config { 'DEFAULT/security_group_api': value => 'nova' }
  nova_config { 'DEFAULT/allow_same_net_traffic': value => 'False' }
  nova_config { 'DEFAULT/multi_host': value => 'True' }
  nova_config { 'DEFAULT/send_arp_for_ha': value => 'True' }
  nova_config { 'DEFAULT/share_dhcp_address': value => 'True' }

}
