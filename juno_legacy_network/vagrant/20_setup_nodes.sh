#!/bin/bash

vagrant ssh control -c "sudo puppet agent --enable"
vagrant ssh compute1 -c "sudo puppet agent --enable"
vagrant ssh compute2 -c "sudo puppet agent --enable"

vagrant ssh control -c "sudo puppet agent -t"
vagrant ssh compute1 -c "sudo puppet agent -t"
vagrant ssh compute2 -c "sudo puppet agent -t"

# sign the certs
vagrant ssh puppet -c "sudo puppet cert sign --all"
