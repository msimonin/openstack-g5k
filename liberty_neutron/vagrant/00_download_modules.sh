#!/bin/bash
# Set up the modules. 
set -x
r10k -v info puppetfile install

# apply patches.
cp -r ../patchs/modules/* modules/.
