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
# First, install Frenetic
#

./bin/setup-frenetic.sh

#
# Dependencies for FlowLog
#

cd

# XSB

wget http://xsb.sourceforge.net/downloads/XSB340.tar.gz
tar xzf XSB*
pushd XSB
cd build
./configure
./makexsb
popd
rm XSB*.tar.gz

echo -e "\n# XSB path" >> ~/.profile
echo -e 'PATH="$HOME/XSB/bin:$PATH"' >> ~/.profile

# PVS

PVS=pvs-6.0-ix86_64-Linux-allegro.tgz
wget -O $PVS "http://pvs.csl.sri.com/cgi-bin/download.cgi?file=$PVS&accept=I+accept"
mkdir pvs
mv $PVS pvs
pushd pvs
tar xzf $PVS
rm $PVS
./bin/relocate
popd

echo -e "\n# PVS path" >> ~/.profile
echo -e 'PATH="$HOME/pvs:$PATH"' >> ~/.profile

source ~/.profile

#
# Clone FlowLog
#

git clone git://github.com/mgscheer/FlowLog.git
