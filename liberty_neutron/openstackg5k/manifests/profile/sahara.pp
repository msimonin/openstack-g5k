class openstackg5k::profile::sahara {

  $controller_address = hiera('openstack::controller::address::management')
  $admin_password = hiera('openstack::keystone::admin_password')
  $allowed_hosts = hiera('openstack::mysql::allowed_hosts')

  # Then, create a database
  class { '::sahara::db::mysql':
    password      => 'a_big_secret',
    allowed_hosts => $allowed_hosts
  }

# Then the common class
  class { '::sahara':
    database_connection => "mysql://sahara:a_big_secret@${controller_address}:3306/sahara",
    verbose             => true,
    debug               => true,
    admin_user          => 'admin',
    admin_password      => "${admin_password}",
    admin_tenant_name   => 'admin',
    auth_uri            => "http://${controller_address}:5000/v2.0/",
    identity_uri        => "http://${controller_address}:35357/",
    host                => '0.0.0.0',
    port                => 8386,
    use_floating_ips    => true,
    use_neutron         => true,
    plugins             => ['vanilla','hdp','spark','cdh', 'storm'] 
  }

# Please note, that if you enabled 'all' service, then you should not enable 'api' and 'engine'. And vice versa.
  class { '::sahara::service::all': }

# Finally, make it accessible
  class { '::sahara::keystone::auth':
    password => 'secrete',
    region   => 'openstack'
  }
}
