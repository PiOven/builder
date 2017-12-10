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

# Change user and group ID
usermod -u 1000 %PI_USERNAME%
groupmod -g 1000 %PI_USERNAME%

# Configure hostname
PI_CONFIG_HOSTNAME="%PI_HOSTNAME%"
for file in $(ls /opt/data); do
  PI_CONFIG_HOSTNAME="${PI_CONFIG_HOSTNAME}-"
  PI_CONFIG_HOSTNAME=${PI_CONFIG_HOSTNAME}$(shuf /opt/data/${file} -n 1 | sed -e "s/\s/-/g")
done

PI_IP_ADDRESS=$(hostname -I)

echo "${PI_CONFIG_HOSTNAME}" > "/etc/hostname"
OLD_HOST="raspberrypi"
sed -i "s/$OLD_HOST/$PI_CONFIG_HOSTNAME/g" "/etc/hosts"
/etc/init.d/hostname.sh

# Send email telling about this server
curl -s --user "api:%PI_MAILGUN_API_KEY%" \
  https://api.mailgun.net/v3/%PI_MAILGUN_DOMAIN%/messages \
  -F from="%PI_USERNAME%@%PI_MAILGUN_DOMAIN%" \
  -F to=%PI_EMAIL_ADDRESS% \
  -F subject="New Raspberry Pi (${PI_CONFIG_HOSTNAME}) set up" \
  -F text="New %PI_USERNAME%@${PI_CONFIG_HOSTNAME} setup on: ${PI_IP_ADDRESS}"

rm -- "$0"

echo "Deleted current script"
