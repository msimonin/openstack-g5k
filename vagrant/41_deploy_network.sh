#!/bin/bash

# the bridge isn't weel configured by the recipes, we explicity configure one before launching the puppet run
vagrant ssh network -c "
sudo apt-get update && sudo apt-get -y install openvswitch-switch; \
sudo ovs-vsctl add-br brex && sudo ovs-vsctl add-port brex eth2 && sudo ifconfig eth2 0.0.0.0 && sudo ifconfig brex 192.168.22.6
sudo puppet agent -t"

wait
