#!/bin/sh

set -e

echo "[$(date)]: Update cronjob started" >> /var/log/update-cronjob

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y

echo "[$(date)]: Update cronjob finished" >> /var/log/update-cronjob
