#!/usr/bin/env bash

sudo wget  https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
sudo dpkg -i puppetlabs-release-trusty.deb
sudo apt-get update
sudo apt-get -y install puppet-common=3.6.1-1puppetlabs1 puppet=3.6.1-1puppetlabs1

