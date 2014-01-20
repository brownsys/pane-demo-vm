#!/bin/bash

# Mininet is already setup by default (by setup-openflow-dev.sh), so this script is
# just for cleaning-up the PANE-focused bits of the VM.

#
# Sanity checks
#

cd

echo 'cat etc/hosts.generic >> /etc/hosts' | sudo bash

#
# Remove PANE demo pieces (temp hack)
#

rm -rf zookeeper demos
rm bin/wrap-*
echo "" > README.md
