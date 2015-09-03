#!/bin/bash

./00_download_modules.sh
./05_up.sh
./10_setup_master.sh
./20_setup_nodes.sh
./30_deploy_control.sh 
./41_deploy_network.sh
./42_deploy_compute.sh
./43_deploy_router.sh
