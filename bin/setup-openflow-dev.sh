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
# Install configuration files into place
#

echo "Installing configuration files..."

sudo cp -f etc/hosts /etc/hosts
sudo cp -f etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf
sudo usermod -a -G nopasswdlogin paneuser

cp /etc/skel/.bashrc .
cp /etc/skel/.profile .
cp /etc/skel/.bash_logout .

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -N "" -f ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    ssh-add || true
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
