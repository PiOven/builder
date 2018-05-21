#!/usr/bin/env bash

###
# User Management
#
# This deletes the "pi" user and creates the user
# as the primary user with the password and public
# key as the ways of accessing the Pi
###

echo "Create our new user: ${PI_USERNAME}"

useradd -m ${PI_USERNAME} -G sudo || true
echo "${PI_USERNAME}:${PI_PASSWORD}" | chpasswd
install -d -m 700 /home/${PI_USERNAME}/.ssh
mv /id_rsa.pub /home/${PI_USERNAME}/.ssh/authorized_keys
chown ${PI_USERNAME}:${PI_USERNAME} -Rf /home/${PI_USERNAME}/.ssh/

echo "Give ${PI_USERNAME} sudoers access"
echo "${PI_USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_${PI_USERNAME}-nopasswd

CURRENT_USER=$(getent passwd "1000" | cut -d: -f1)
echo "Now delete the current user: ${CURRENT_USER}"
rm /etc/sudoers.d/010_${CURRENT_USER}-nopasswd
deluser -remove-home ${CURRENT_USER}

echo "Change user and group ID to 1000 for ${PI_USERNAME}"
usermod -u 1000 ${PI_USERNAME}
groupmod -g 1000 ${PI_USERNAME}
