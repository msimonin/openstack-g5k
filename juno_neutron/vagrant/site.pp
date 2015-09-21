node 'puppet' {
  include ::ntp
}

node 'control.localdomain' {
  include ::openstackg5k::role::controller
}

node 'network.localdomain' {
  include ::openstackg5k::role::network
}

node 'compute.localdomain' {
  include ::openstack::role::compute
}

node 'tempest.localdomain' {
  include ::openstack::role::tempest
}

