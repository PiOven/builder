#!/bin/sh

exec 2> /var/log/rc.local.log # send stderr from rc.local to a log file
exec 1>&2

set -x
set -e

useradd -m %USERNAME% -G sudo || true
echo "%USERNAME%:%PASSWORD%" | chpasswd
install -d -m 700 /home/%USERNAME%/.ssh
mv /id_rsa.pub /home/%USERNAME%/.ssh/authorized_keys
chown %USERNAME%:%USERNAME% /home/%USERNAME%/.ssh/

echo "%USERNAME% ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_%USERNAME%-nopasswd

rm /etc/sudoers.d/010_pi-nopasswd
deluser -remove-home pi

rm -- "$0"

echo "Deleted current script"
