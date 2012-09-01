#!/bin/bash

PANE_SCRIPTS="/home/paneuser/pane/scripts"

sudo $PANE_SCRIPTS/ovs-set-port-queue-min.sh $*

# An alternative useful for development.
# ssh -p 2222 paneuser@localhost "PANE_SCRIPTS/ovs-set-port-queue-min.sh $*"
