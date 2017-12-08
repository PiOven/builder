#!/bin/sh

exec 2> /var/log/rc.local.log # send stderr from rc.local to a log file
exec 1>&2

set -x
set -e

# Delete "pi" user and create another one
useradd -m %PI_USERNAME% -G sudo || true
echo "%PI_USERNAME%:%PI_PASSWORD%" | chpasswd
install -d -m 700 /home/%PI_USERNAME%/.ssh
mv /id_rsa.pub /home/%PI_USERNAME%/.ssh/authorized_keys
chown %PI_USERNAME%:%PI_USERNAME% -Rf /home/%PI_USERNAME%/.ssh/

echo "%PI_USERNAME% ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_%PI_USERNAME%-nopasswd

rm /etc/sudoers.d/010_pi-nopasswd
deluser -remove-home pi

# Configure hostname
PI_IP_ADDRESS=$(hostname -I)
PI_HOST_IP=$(echo ${PI_IP_ADDRESS} | sed -e "s/\./-/g")
PI_CONFIG_HOSTNAME="%PI_HOSTNAME%-${PI_HOST_IP}"

echo "${PI_CONFIG_HOSTNAME}" > "/etc/hostname"
OLD_HOST="raspberrypi"
sed -i "s/$OLD_HOST/$PI_CONFIG_HOSTNAME/g" "/etc/hosts"
/etc/init.d/hostname.sh

rm -- "$0"

echo "Deleted current script"
