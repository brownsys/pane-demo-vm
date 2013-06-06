#!/bin/bash

# This script is intended to install PANE into
# a brand-new Ubuntu Server virtual machine,
# to create a fully usable demo VM.
# Inspired by Mininet VM creation script
# Last tested with Ubuntu Server 12.10 x64

set -e

echo `whoami` ALL=NOPASSWD: ALL | sudo tee -a /etc/sudoers
sudo sed -i -e 's/Default/#Default/' /etc/sudoers

sudo apt-get update

##
# Install Xubuntu as a nice minimal interface
##

sudo apt-get -y install xubuntu-desktop

##
# Clean-off unnecessary stuff
##

sudo apt-get -y --purge remove abiword abiword-common
sudo apt-get -y --purge remove account-plugin-facebook
sudo apt-get -y --purge remove account-plugin-flickr
sudo apt-get -y --purge remove account-plugin-google
sudo apt-get -y --purge remove gmusicbrowser
sudo apt-get -y --purge remove gnome-sudoku
sudo apt-get -y --purge remove gnome-games-data
sudo apt-get -y --purge remove pidgin
sudo apt-get -y --purge remove rhythmbox
sudo apt-get -y --purge remove thunderbird
sudo apt-get -y --purge remove transmission-gtk transmission-common
sudo apt-get -y --purge remove media-player-info
sudo apt-get -y --purge remove xscreensaver xscreensaver-gl xscreensaver-data
sudo apt-get -y --purge remove bluez
sudo apt-get -y --purge remove evolution-data-server evolution-data-server-common
sudo apt-get -y --purge remove firefox
sudo apt-get -y --purge remove ppp
sudo apt-get -y --purge remove cups cups-common
sudo apt-get -y --purge remove printer-driver*
sudo apt-get -y --purge remove linux-sound-base
sudo apt-get -y --purge remove xfburn
sudo apt-get -y --purge remove parole
sudo apt-get -y --purge remove pulseaudio
sudo apt-get -y --purge remove gthumb
sudo apt-get -y --purge remove ristretto
sudo apt-get -y --purge remove xchat
sudo apt-get -y --purge remove gstreamer*
sudo apt-get -y --purge remove evince
sudo apt-get -y --purge remove simple-scan sane-utils libsane libsane-common
sudo apt-get -y --purge remove orage
sudo apt-get -y --purge remove catfish
sudo apt-get -y --purge remove leafpad
sudo apt-get -y --purge remove xfce4-notes xfce4-notes-plugin
sudo apt-get -y --purge remove gcalctool
sudo apt-get -y --purge remove vala-terminal
sudo apt-get -y --purge remove file-roller
sudo apt-get -y --purge remove xfce4-dict dictionaries-common
sudo apt-get -y --purge remove genisoimage
sudo apt-get -y --purge remove ntfs-3g
sudo apt-get -y --purge remove samba-common samba-common-bin
sudo apt-get -y --purge remove alsa-utils
sudo apt-get -y --purge remove foomatic*
sudo apt-get -y --purge remove speech-dispatcher espeak espeak-data
sudo apt-get -y --purge remove openprinting-ppds
sudo apt-get -y --purge remove mysql-common
sudo apt-get -y --purge remove w3m
sudo apt-get -y --purge remove dosfstools
sudo apt-get -y --purge remove libsmbclient
sudo apt-get -y --purge remove sound-theme-freedesktop

sudo apt-get -y --purge autoremove
sudo apt-get -y upgrade

##
# Needed for development, etc.
##

sudo apt-get -y install openssh-server
sudo apt-get -y install git
sudo apt-get -y install vim-gtk
sudo apt-get -y install emacs
sudo apt-get -y install linux-crashdump

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# we expect installing google-chrome to "fail", but we fix with apt-get
set +e
sudo dpkg -i google-chrome*
set -e
sudo apt-get -y install -f
rm google-chrome*

##
# Install OpenFlow development VM
# and (optionally) a PANE demo setup
##

cd ~
set +e
sudo rm -rf .* *
set -e
git clone git://github.com/brownsys/pane-demo-vm.git .
./bin/setup-openflow-dev.sh
./bin/setup-demo.sh

sudo apt-get -y --purge remove avahi-daemon libnss-mdns
sudo apt-get -y --purge autoremove
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y --purge autoremove
sudo apt-get clean

sudo /sbin/reboot
