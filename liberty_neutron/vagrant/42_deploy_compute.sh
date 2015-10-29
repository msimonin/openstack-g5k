#!/bin/bash

vagrant ssh compute -c "sudo puppet agent -t"

wait
