#!/bin/bash

sudo modprobe openvswitch

sudo ovsdb-server /usr/local/etc/openvswitch/ovs-vswitchd.conf.db -vANY:CONSOLE:EMER -vANY:SYSLOG:ERR -vANY:FILE:INFO --remote=punix:/usr/local/var/run/openvswitch/db.sock --remote=db:Open_vSwitch,manager_options --private-key=db:SSL,private_key --certificate=db:SSL,certificate --bootstrap-ca-cert=db:SSL,ca_cert --no-chdir --log-file=/var/log/openvswitch/ovsdb-server.log --pidfile=/usr/local/var/run/openvswitch/ovsdb-server.pid --detach --monitor

sudo ovs-vswitchd unix:/usr/local/var/run/openvswitch/db.sock -vANY:CONSOLE:EMER -vANY:SYSLOG:ERR -vANY:FILE:INFO --mlockall --no-chdir --log-file=/var/log/openvswitch/ovs-vswitchd.log --pidfile=/usr/local/var/run/openvswitch/ovs-vswitchd.pid --detach --monitor
