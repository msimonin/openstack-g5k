#!/bin/bash

vagrant ssh compute1 -c "sudo puppet agent -t"
vagrant ssh compute2 -c "sudo puppet agent -t"

wait
