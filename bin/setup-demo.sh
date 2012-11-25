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

cabal update

# install maven3 by hand

if [ "`which mvn`" == "" ]; then
    wget http://ftp.heanet.ie/mirrors/www.apache.org/dist/maven/binaries/apache-maven-3.0.4-bin.tar.gz
    sudo cp -R apache-maven-3.0.4 /usr/local
    sudo ln -s /usr/local/apache-maven-3.0.4/bin/mvn /usr/bin/mvn
    rm -rf apache-maven-3.0.4
    rm apache-maven-3.0.4-bin.tar.gz
fi

#
# Install and build Mininet
#

echo "Installing and building mininet-hifi..."

if [ ! -d "mininet" ]; then
#    git clone git://github.com/mininet/mininet.git
# Temporarily use my fork until some patches are applied upstream
    git clone git://github.com/adferguson/mininet.git
    cd mininet
    git checkout -t origin/class/cs244
    cd ..
fi

pushd mininet

git checkout class/cs244

# fix small bug in util/install.sh
cat util/install.sh | sed "s/install git$/install git-core/" > util/install.sh-fixed
mv -f util/install.sh-fixed util/install.sh
chmod a+x util/install.sh

if [ ! -d ~/openflow ]; then
    ./util/install.sh -f
fi

if [ ! -d ~/openvswitch ]; then
    ./util/install.sh -v
fi

./util/install.sh -kmntw
sudo make develop

popd

#
# Open vSwitch setup
#

echo "Setting-up Open vSwitch..."

if [ -f /usr/local/etc/ovs-vswitchd.conf.db ]; then
    rm /usr/local/etc/ovs-vswitchd.conf.db
fi

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
