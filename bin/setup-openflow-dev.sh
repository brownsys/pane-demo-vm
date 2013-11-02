#!/bin/bash

# Fail on error
set -e

# Fail on unset var usage
set -o nounset

#
# Sanity checks
#

cd

#
# Install and build Mininet
#

echo "Installing and building mininet..."

if [ ! -d "mininet" ]; then
    git clone git://github.com/mininet/mininet.git
fi

pushd mininet

# use our OpenFlow reference switch
cat util/install.sh | sed "s/\/openflowswitch.org/\/github.com\/brownsys/" > util/install.sh-fixed
mv -f util/install.sh-fixed util/install.sh
chmod a+x util/install.sh

if [ ! -d ~/openflow ]; then
    ./util/install.sh -f
fi

if [ "`which ovsdb-tool`" == "" ]; then
    ./util/install.sh -v
fi

if [ ! -d ~/of-dissector ]; then
    ./util/install.sh -w
fi

./util/install.sh -nt
sudo make develop

popd

#
# Open vSwitch setup
#

echo "Setting-up Open vSwitch..."

sudo service openvswitch-switch stop

OVS_CONF=/var/lib/openvswitch/conf.db
OVS_SCHEMA=/usr/share/openvswitch/vswitch.ovsschema

if [ -f $OVS_CONF ]; then
    sudo rm $OVS_CONF
fi

sudo ovsdb-tool create $OVS_CONF $OVS_SCHEMA
