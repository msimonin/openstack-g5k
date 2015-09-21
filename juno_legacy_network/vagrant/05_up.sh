#!/bin/bash
# This is the script for bringing up the standard openstack nodes without
# Swift. This is probably the up script you want to run.
vagrant up puppet control compute1 compute2

wait
