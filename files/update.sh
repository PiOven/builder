#!/bin/sh

exec &> /var/log/update-cronjob

set -e
set -x

echo "[$(date)]: Update cronjob started" >> /var/log/update-cronjob

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y

echo "[$(date)]: Update cronjob finished" >> /var/log/update-cronjob

# Check if we need to reboot the Pi
if [ -f /var/run/reboot-required.pkgs ]; then
  echo "[$(date)]: Rebooting after update cronjob" >> /var/log/update-cronjob
  reboot
fi
