class openstackg5k::role::network inherits ::openstack::role {
  class { '::openstack::profile::firewall': }
  class { '::openstack::profile::neutron::router': }
  # Matt we remove the bootstrap of new network 
  # This seems problematic  (ntx not well configured / wrong vlan id on network node ....)
  class { '::openstack::setup::sharednetwork': }
}
