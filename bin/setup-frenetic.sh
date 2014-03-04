#!/bin/bash

#
# Sanity checks
#

cd

echo 'cat etc/hosts.generic >> /etc/hosts' | sudo bash

#
# Install OCaml 4.0.1.0 and OPAM 1.1.0 from @avsm's PPA
# based on Frenetic project's Travis CI scripts
#

sudo apt-get -y install python-software-properties software-properties-common libssl-dev

echo "yes" | sudo add-apt-repository ppa:avsm/ocaml41+opam11
sudo apt-get update
sudo apt-get -y install ocaml ocaml-native-compilers camlp4-extra opam

export OPAMYES=1
export OPAMVERBOSE=1
echo OCaml version
ocaml -version
echo OPAM versions
opam --version
opam --git-version

#
# Install OPAM
#

set +e
opam init -y || true
eval `opam config env`
. ~/.opam/opam-init/init.sh || true
set -e

#
# Install dependencies for Frenetic
#

sudo apt-get install -y ctags

opam update
opam install -y base-unix base-threads base-bigarray ssl react lablgtk ocaml-text
opam install -y cstruct lwt ocamlfind ocamlgraph ounit pa_ounit quickcheck
opam upgrade

#
# Install Frenetic
#

git clone git://github.com/adferguson/ocaml-packet.git
cd ocaml-packet
ocaml setup.ml -configure --enable-tests --enable-quickcheck
make && make install
cd

git clone git://github.com/adferguson/ocaml-openflow.git
cd ocaml-openflow
ocaml setup.ml -configure --enable-tests --enable-quickcheck --enable-lwt
make && make install
cd

git clone git://github.com/frenetic-lang/ocaml-topology.git
cd ocaml-topology
make && make install
cd

git clone git://github.com/adferguson/frenetic.git
cd frenetic
make
sudo make install
cd

echo -e "\nexport OCAMLRUNPARAM=b\n" >> ~/.bashrc
echo -e '\neval `opam config env`\n' >> ~/.bashrc

#
# Remove PANE demo pieces (temp hack)
#

rm -rf zookeeper demos
rm bin/wrap-*
echo "" > README.md
