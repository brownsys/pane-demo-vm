#!/bin/bash

# Fail on error
set -e

# Fail on unset var usage
set -o nounset

#
# Sanity checks
#

cd

sudo cat etc/hosts.generic >> /etc/hosts

#
# Install and build OCaml
#

wget http://caml.inria.fr/pub/distrib/ocaml-4.00/ocaml-4.00.1.tar.bz2
tar xjf ocaml*
cd ocaml*
./configure && make world.opt && sudo make install

#
# Install OPAM
#

echo "deb [arch=amd64] http://www.recoil.org/~avsm/ wheezy main" >> /etc/apt/sources.list
sudo apt-get update
sudo apt-get -y --force-yes install opam
opam init -y
. ~/.opam/opam-init/init.sh

#
# Install dependencies for Frenetic
#

sudo apt-get install -y screen
sudo apt-get install -y ctags

opam install -y ocamlfind cstruct lwt ounit

#
# Install Frenetic
#

git clone git://github.com/frenetic-lang/frenetic.git
cd frenetic
make
cd

sudo ln -s ~/frenetic/src/Frenetic.d.byte /usr/local/bin/frenetic

echo -e "\nexport OCAMLRUNPARAM=b\n" >> ~/.bashrc

#
# Remove PANE demo pieces (temp hack)
#

rm -rf zookeeper demos
rm bin/wrap-*
echo "" > README.md
