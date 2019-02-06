#!/bin/sh

exec 2> /var/log/rc.local.log # send stderr from rc.local to a log file
exec 1>&2

set -x
set -e

DATA_DIR=/opt/data

# Delete "pi" user and create another one
useradd -m %PI_USERNAME% -G sudo || true
echo "%PI_USERNAME%:%PI_PASSWORD%" | chpasswd
install -d -m 700 /home/%PI_USERNAME%/.ssh
mv /id_rsa.pub /home/%PI_USERNAME%/.ssh/authorized_keys
chown %PI_USERNAME%:%PI_USERNAME% -Rf /home/%PI_USERNAME%/.ssh/

echo "%PI_USERNAME% ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_%PI_USERNAME%-nopasswd

rm /etc/sudoers.d/010_pi-nopasswd
deluser -remove-home pi

# Change user and group ID
usermod -u 1000 --shell /bin/bash %PI_USERNAME%
groupmod -g 1000 %PI_USERNAME%

# Configure hostname
randomWord1=$(shuf ${DATA_DIR}/words.txt -n 1 | sed -e "s/\s/-/g")
randomWord2=$(shuf ${DATA_DIR}/words.txt -n 1 | sed -e "s/\s/-/g")
PI_CONFIG_HOSTNAME="%PI_HOSTNAME%-${randomWord1}-${randomWord2}"

echo "${PI_CONFIG_HOSTNAME}" > "/etc/hostname"
OLD_HOST="raspberrypi"
sed -i "s/$OLD_HOST/$PI_CONFIG_HOSTNAME/g" "/etc/hosts"
hostnamectl set-hostname "${PI_CONFIG_HOSTNAME}"

# Configure the memory split
if test "%PI_GPU_MEMORY%" = "16" || test "%PI_GPU_MEMORY%" = "32" || test "%PI_GPU_MEMORY%" = "64" || test "%PI_GPU_MEMORY%" = "128" || test "%PI_GPU_MEMORY%" = "256"; then
  echo "gpu_mem=%PI_GPU_MEMORY%" >> /boot/config.txt
fi

# Configure static IP address
apt-get -qq update
apt-get install -y python-dev python-pip
pip install netifaces

export TARGET_IP="target_ip"
export NETWORK_CONFIG="/etc/network/interfaces"
export PI_IP_ADDRESS_RANGE_START="%PI_IP_ADDRESS_RANGE_START%"
export PI_IP_ADDRESS_RANGE_END="%PI_IP_ADDRESS_RANGE_END%"
export PI_DNS_ADDRESS="%PI_DNS_ADDRESS%"
python /interfaces.py

cat /etc/network/interfaces
rm /interfaces.py
pip uninstall -y netifaces
apt-get remove -y python-dev python-pip

PI_IP_ADDRESS=$(cat ./target_ip)
rm ./target_ip

# Remove DHCPCD5 - https://www.raspberrypi.org/forums/viewtopic.php?t=111709
apt-get remove -y dhcpcd5

# Install Docker
if "%PI_INSTALL_DOCKER%" -eq "true"; then
  curl -sSL https://get.docker.com | CHANNEL=stable sh
  usermod -aG docker %PI_USERNAME%
fi

# Send email telling about this server
if test "%PI_MAILGUN_API_KEY%" && test "%PI_MAILGUN_DOMAIN%" && test "%PI_EMAIL_ADDRESS%"; then
  curl -s --user "api:%PI_MAILGUN_API_KEY%" \
    https://api.mailgun.net/v3/%PI_MAILGUN_DOMAIN%/messages \
    -F from="%PI_USERNAME%@%PI_MAILGUN_DOMAIN%" \
    -F to=%PI_EMAIL_ADDRESS% \
    -F subject="New Raspberry Pi (${PI_CONFIG_HOSTNAME}) set up" \
    -F text="New %PI_USERNAME%@${PI_CONFIG_HOSTNAME} setup on: ${PI_IP_ADDRESS}"
fi

rm -Rf ${DATA_DIR}

rm -- "$0"

echo "Deleted current script"
