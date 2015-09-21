# The puppet module to set up a Nova Compute node
class openstackg5k::profile::nova::compute {
  $management_network            = $::openstack::config::network_management
  $management_address            = ip_for_network($management_network)
  $controller_management_address = $::openstack::config::controller_address_management

  include ::openstackg5k::common::nova

  class { '::nova::compute':
    enabled                       => true,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => $management_address,
    vncproxy_host                 => $::openstack::config::controller_address_api,
  } -> 
  /*Matt: Metadata api*/
  package { 'python-memcache':
    ensure => present,
  } ->
  package { 'nova-api-metadata':
    ensure  => present,
    require => Package['python-memcache']
  }
 
  class { '::nova::compute::libvirt':
    libvirt_virt_type => $::openstack::config::nova_libvirt_type,
    vncserver_listen  => $management_address,
  }

  class { 'nova::migration::libvirt':
  }

  file { '/etc/libvirt/qemu.conf':
    ensure => present,
    source => 'puppet:///modules/openstack/qemu.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['libvirt'],
  }

  if $::osfamily == 'RedHat' {
    package { 'device-mapper':
      ensure => latest
    }
    Package['device-mapper'] ~> Service['libvirtd'] ~> Service['nova-compute']
  }
  Package['libvirt'] -> File['/etc/libvirt/qemu.conf']

 
  package { 'bridge-utils':
   ensure => present, 
  }

  exec { 'brctl addbr br100 && ifconfig br100 up && ifconfig br100 promisc':
    path    => ['/sbin', '/bin'],
    require => Package['bridge-utils'],
    unless  => 'brctl show | grep br100'
    # add an unless to be idempotent
  } 

  class { '::nova::network':
    enabled         => true,
    create_networks => false
  } 
}
