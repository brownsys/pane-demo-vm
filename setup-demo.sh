#!/bin/bash

# Fail on error
set -e

# Fail on unset var usage
set -o nounset

#
# Sanity checks
# 

if [ `hostname` != "panedemo" ]; then
    echo "This script is designed to be run on the PANE demo VM. Exiting."
    exit
fi

if [ `whoami` != "paneuser" ]; then
    echo "This script expects to be run as 'paneuser'. Exiting."
    exit
fi

#
# Install configuration files into place 
#

echo "Installing configuration files..."

sudo cp -f etc/hosts /etc/hosts

cp /etc/skel/.bashrc .
cp /etc/skel/.profile .
cp /etc/skel/.bash_lougout .

echo "cat ~/README.md" >> ~/.bashrc

ssh-keygen -N "" -f ~/.ssh/id_rsa
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

#
# Install dependencies we know we need
#

echo "Installing dependencies..."

sudo apt-get -y install ant
sudo apt-get -y install default-jdk

#
# Install and build Mininet
#

echo "Installing and building mininet-hifi..."

if [ ! -d "mininet" ]; then
    git clone git://github.com/mininet/mininet.git
    cd mininet
    git checkout -t origin/class/cs244
    cd ..
fi

pushd mininet

git checkout class/cs244
./util/install.sh -a
sudo make develop

popd

#
# Open vSwitch setup
#

echo "Setting-up Open vSwitch..."

pushd ~/openvswitch
sudo ovsdb-tool create /usr/local/etc/ovs-vswitchd.conf.db vswitchd/vswitch.ovsschema
popd

#
# Install and build Nettle
#

echo "Installing and building brownsys-nettle..."

if [ ! -d "brownsys-nettle" ]; then
    git clone git://github.com/brownsys/nettle-openflow.git brownsys-nettle
fi

pushd brownsys-nettle
cabal install --only-dependencies
cabal configure
cabal build
cabal install
popd

#
# Install and build PANE 
#

echo "Installing and building PANE ..."

if [ ! -d "pane" ]; then
    git clone git://github.com/brownsys/pane.git
fi

pushd pane
cabal install --only-dependencies
make
popd


#
# Install and build ZooKeeper
#

echo "Installing and building ZooKeeper..."

pushd zookeeper

if [ ! -d "pane-zookeeper" ]; then
    git clone git://github.com/brownsys/pane-zookeeper.git
fi

cd pane-zookeeper

git pull
ant jar

popd
