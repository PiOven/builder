#!/bin/bash

###
# Install Py Deps
#
# Installs requires Python dependencies for
# setup
###

echo "Install Python dependencies"

apt-get update
apt-get install -y python-dev python-pip
pip install netifaces
