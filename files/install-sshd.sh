#!/bin/bash
set -e

# Install required packages
apt update -qq
apt -y --no-install-recommends install openssh-server
mkdir /var/run/sshd

# Generate host keys
ssh-keygen -A

# Configure SSH
# echo "PermitRootLogin no" >> /etc/ssh/sshd_config
# echo "UsePAM yes" >> /etc/ssh/sshd_config
# replaced by new default config


echo "Cleaning up after installation..."
apt clean
apt autoremove -y
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
