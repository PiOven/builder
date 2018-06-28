#!/bin/bash

###
# Remove Py Deps
#
# Removes requires Python dependencies for
# setup
###

echo "Remove Python dependencies"

pip uninstall -y netifaces
apt-get remove -y python-dev python-pip
apt-get -y autoremove
apt-get -y autoclean
