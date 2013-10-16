#!/bin/bash

# Fail on error
set -e

# Fail on unset var usage
set -o nounset

#
# Sanity checks
#

cd

echo 'cat etc/hosts.generic >> /etc/hosts' | sudo bash

#
# Install and build OCaml
#

wget http://caml.inria.fr/pub/distrib/ocaml-4.00/ocaml-4.00.1.tar.bz2
tar xjf ocaml*
pushd ocaml*
./configure && make world.opt && sudo make install
popd
rm ocaml*.tar.bz2

#
# Install OPAM
#

echo 'echo "deb [arch=amd64] http://www.recoil.org/~avsm/ wheezy main" >> /etc/apt/sources.list' | sudo bash
sudo apt-get update
sudo apt-get -y --force-yes install opam
set +e
opam init -y || true
. ~/.opam/opam-init/init.sh || true
set -e

#
# Install dependencies for Frenetic
#

sudo apt-get install -y ctags

opam install -y cstruct lwt ocamlfind ocamlgraph ounit pa_ounit quickcheck

#
# Install Frenetic
#

git clone git://github.com/frenetic-lang/ocaml-packet.git
cd ocaml-packet
git checkout 968d4ae10275be23b152aca511a3b45392732009
make && make install
cd

git clone git://github.com/frenetic-lang/ocaml-openflow.git
cd ocaml-openflow
git checkout 3a6aa098de71ae5a3ab9787f519840d145db998c
make && make install
cd

git clone git://github.com/frenetic-lang/ocaml-topology.git
cd ocaml-topology
make && make install
cd

git clone git://github.com/frenetic-lang/frenetic.git
cd frenetic
git checkout ba9814de76e707d66a1c1a530cc2b59e00da3791
make
sudo make install
cd

echo -e "\nexport OCAMLRUNPARAM=b\n" >> ~/.bashrc

#
# Remove PANE demo pieces (temp hack)
#

rm -rf zookeeper demos
rm bin/wrap-*
echo "" > README.md
