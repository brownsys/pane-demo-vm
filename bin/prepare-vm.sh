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

cat etc/hosts.in | sed s/HOSTNAME/`hostname`/g > etc/hosts
sudo cp -f etc/hosts /etc/hosts

cat etc/lightdm/lightdm.conf.in | sed s/USERNAME/`whoami`/g > etc/lightdm/lightdm.conf
sudo cp -f etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf

sudo usermod -a -G nopasswdlogin `whoami`

cp /etc/skel/.bashrc .
cp /etc/skel/.profile .
cp /etc/skel/.bash_logout .

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -N "" -f ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    ssh-add || true
    ssh -o StrictHostKeyChecking=no localhost /bin/true
    ssh -o StrictHostKeyChecking=no `hostname` /bin/true
fi

echo -e "\n# Route Setup\n" >> ~/.bashrc
echo "if [ \"\`sudo route -n | grep \"127.0.0.1\"\`\" == \"\" ]; then" >> ~/.bashrc
echo "    sudo route add -host 127.0.0.1 dev lo" >> ~/.bashrc
echo "fi" >> ~/.bashrc

echo -e "\n# Cleaning\n" >> ~/.bashrc
echo "if [ -d \"Documents\" ]; then" >> ~/.bashrc
echo "    rmdir Documents Downloads Music Pictures Public Templates Videos" >> ~/.bashrc
echo "fi" >> ~/.bashrc
