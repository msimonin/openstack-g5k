class openstackg5k::role::network inherits ::openstack::role {
  class { '::openstack::profile::firewall': }
  class { '::openstack::profile::neutron::router': }
  class { '::openstack::setup::sharednetwork': }
  
  # Matt sets custom dnsmasq conf file 
  # e.g for mtu 
  file { '/etc/dnsmasq.conf':
    ensure  => present,
    source  => "puppet:///modules/openstackg5k/dnsmasq.conf",
    notify  => Service["neutron-dhcp-agent"]
  }

}
