#!/bin/bash

vagrant ssh control -c "sudo puppet agent -t"

wait
