# Install required packages
apt update -qq
apt -y --no-install-recommends install openssh-server
mkdir /var/run/sshd

# Create jovyan user with sudo capabilities
useradd -m -s /bin/bash jovyan
echo "jovyan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan
mkdir -p /home/jovyan/.ssh
chown -R jovyan:jovyan /home/jovyan

# Generate host keys
ssh-keygen -A

# Configure SSH
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "UsePAM yes" >> /etc/ssh/sshd_config