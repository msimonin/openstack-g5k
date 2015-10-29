#!/bin/bash

vagrant ssh control -c "sudo puppet agent --enable"
vagrant ssh network -c "sudo puppet agent --enable"
vagrant ssh compute -c "sudo puppet agent --enable"

vagrant ssh control -c "sudo puppet agent -t"
vagrant ssh network -c "sudo puppet agent -t"
vagrant ssh compute -c "sudo puppet agent -t"

# sign the certs
vagrant ssh puppet -c "sudo puppet cert sign --all"
