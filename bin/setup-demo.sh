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

echo 'cat etc/hosts.pane >> /etc/hosts' | sudo bash

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
