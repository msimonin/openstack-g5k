node 'puppet' {
  include ::ntp
}

node 'control.localdomain' {
  include ::openstackg5k::role::controller
}

node 'network.localdomain' {
  include ::openstackg5k::role::network
}

node 'compute1.localdomain' {
  include ::openstackg5k::role::compute
}

node 'compute2.localdomain' {
  include ::openstackg5k::role::compute
}

node 'tempest.localdomain' {
  include ::openstack::role::tempest
}

