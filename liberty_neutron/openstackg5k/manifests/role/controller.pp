class openstackg5k::role::controller inherits ::openstack::role {
  class { '::openstack::profile::firewall': }
  class { '::openstack::profile::rabbitmq': } ->
  class { '::openstack::profile::memcache': } ->
  class { '::openstack::profile::mysql': } ->
  class { '::openstack::profile::mongodb': } ->
  class { '::openstack::profile::keystone': } ->
  #  class { '::openstack::profile::swift::proxy': } ->
  class { '::openstack::profile::ceilometer::api': } ->
  class { '::openstack::profile::glance::auth': } ->
  class { '::openstack::profile::cinder::api': } ->
  class { '::openstack::profile::nova::api': } ->
  class { '::openstack::profile::neutron::server': } ->
  class { '::openstack::profile::heat::api': } ->

  # Matt (install the storage on the same node)
  # the following are borrowed from openstack::role::storage
  # firewall recipes has been removed since they are redundant
  class { '::openstack::profile::glance::api': } ->
  class { '::openstack::profile::cinder::volume': } ->
  # /Matt

  class { '::openstack::profile::horizon': }
  class { '::openstack::profile::auth_file': }
}
