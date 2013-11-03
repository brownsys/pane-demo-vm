#!/bin/bash

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

source ~/.profile

#
# Clone FlowLog
#

git clone git://github.com/tnelson/FlowLog.git

opam install -y extlib thrift yojson
