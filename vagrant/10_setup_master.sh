#!/bin/bash

set -x

vagrant ssh puppet -c "
sudo rmdir /etc/puppet/modules || sudo unlink /etc/puppet/modules; \
sudo ln -s /openstack/modules /etc/puppet/modules; \
sudo ln -s /openstack/site.pp /etc/puppet/manifests/site.pp; \
sudo ln -s /openstackg5k /etc/puppet/modules/openstackg5k; \
sudo ln -s /openstack/hiera.yaml /etc/puppet/hiera.yaml; \
sudo ln -s /openstack/hieradata /etc/puppet/hieradata; \
sudo service puppetmaster start; \
sudo puppet agent --enable; \ 
sudo puppet agent -t;"
