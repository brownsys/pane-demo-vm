#!/bin/bash

PANE_SCRIPTS="/home/paneuser/pane/scripts"

sudo $PANE_SCRIPTS/ovs-delete-port-queue.sh $*

# An alternative useful for development.
# ssh -p 2222 paneuser@localhost "sudo $PANE_SCRIPTS/ovs-delete-port-queue.sh $*"
