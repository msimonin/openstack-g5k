class openstackg5k::role::compute inherits ::openstack::role {
  class { '::openstack::profile::firewall': }
  class { '::openstackg5k::profile::nova::compute': } ->
  class { '::openstack::profile::ceilometer::agent': }
}
