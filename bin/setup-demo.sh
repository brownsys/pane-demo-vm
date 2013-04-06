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

cd /home/paneuser

#
# Install configuration files into place
#

echo "Installing configuration files..."

sudo cp -f etc/hosts /etc/hosts
sudo cp -f etc/lightdm/lightdm.conf /etc/lightdm.conf
sudo useradd -G nopasswdlogin paneuser

cp /etc/skel/.bashrc .
cp /etc/skel/.profile .
cp /etc/skel/.bash_logout .

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -N "" -f ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    ssh-add
    ssh -o StrictHostKeyChecking=no localhost /bin/true
    ssh -o StrictHostKeyChecking=no panedemo /bin/true
fi

echo -e "\n# Route Setup\n" >> ~/.bashrc
echo "if [ \"\`sudo route -n | grep \"127.0.0.1\"\`\" == \"\" ]; then" >> ~/.bashrc
echo "    sudo route add -host 127.0.0.1 dev lo" >> ~/.bashrc
echo "fi" >> ~/.bashrc

echo -e "\n# Cleaning\n" >> ~/.bashrc
echo "if [ -d \"Documents\" ]; then" >> ~/.bashrc
echo "    rmdir Documents Downloads Music Pictures Public Templates Videos" >> ~/.bashrc
echo "fi" >> ~/.bashrc

#
# Install dependencies we know we need
#

echo "Installing dependencies..."

sudo apt-get -y install ant
sudo apt-get -y install default-jdk
sudo apt-get -y install maven
sudo apt-get -y install haskell-platform
sudo apt-get -y install haskell-platform-prof

cabal update

#
# Install and build Mininet
#

echo "Installing and building mininet..."

if [ ! -d "mininet" ]; then
#    git clone git://github.com/mininet/mininet.git
# Temporarily use my fork until some patches are applied upstream
    git clone git://github.com/adferguson/mininet.git
    cd mininet
    git checkout -t origin/adf-tc-renumber
    cd ..
fi

pushd mininet

git checkout adf-tc-renumber

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
    cd pane
    git checkout -t origin/nib-rewrite
    cd ..
fi

pushd pane
git checkout nib-rewrite
cabal install --only-dependencies
make
make clientlibs
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

# Get the custom ZooKeeper jar into our Maven repo
cd build

ZK_VER=`ls -1 zookeeper-*.jar | sed s/^zookeeper-// | sed s/\.jar$//`
mvn install:install-file -Dfile=zookeeper-$ZK_VER.jar -DgroupId=org.apache.zookeeper -DartifactId=zookeeper -Dversion=$ZK_VER -Dpackaging=jar

popd

#
# Install and build ZooKeeper benchmark

echo "Installing and building ZooKeeper Benchmark..."

pushd zookeeper

if [ ! -d "zookeeper-benchmark" ]; then
    git clone git://github.com/brownsys/zookeeper-benchmark.git
fi

cd zookeeper-benchmark

git pull

mvn -DZooKeeperVersion=$ZK_VER package

popd
