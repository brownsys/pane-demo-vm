#!/bin/bash

sudo modprobe openvswitch_mod

sudo ovsdb-server /usr/local/etc/ovs-vswitchd.conf.db --remote=punix:/usr/local/var/run/openvswitch/db.sock --detach

sudo ovs-vswitchd --detach unix:/usr/local/var/run/openvswitch/db.sock
