#!/bin/bash
set -e

# Generate SSH key for vagrant user if not exists
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
  sudo -u vagrant ssh-keygen -t rsa -b 4096 -N "" -f /home/vagrant/.ssh/id_rsa
fi

# Add public key to authorized_keys
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
