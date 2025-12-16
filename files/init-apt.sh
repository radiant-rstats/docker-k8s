#!/bin/bash
set -e  # Exit on error

echo "Installing packages that are needed for all next steps"

# Update package list with reduced output
apt update -qq || { echo "Failed to update package list"; exit 1; }

# System utilities
echo "Installing system utilities..."
apt -y install \
  liblzma5 \
  liblzma-dev \
  sudo \
  gosu \
  curl \
  lsb-release \
  wget \
  ca-certificates \
  gdebi-core \
  locales

# Shell and editors
echo "Installing shell and editors..."
apt -y install \
  zsh \
  autojump \
  vim \
  vifm

# Development tools
echo "Installing development tools..."
apt -y install \
  git \
  git-lfs \
  rsync

# System monitoring
echo "Installing monitoring tools..."
apt -y install \
  htop \
  lsof

# File management
echo "Installing file management tools..."
apt -y install \
  rename

echo "Cleaning up after installation..."
apt clean
apt autoremove -y

# Configure locales
echo "Configuring locales..."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
update-ca-certificates -f || { echo "Failed to update certificates"; exit 1; }
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup user permissions
echo "Configuring user permissions..."
echo "jovyan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan
chmod 0440 /etc/sudoers.d/jovyan

# Set shell for jovyan user
echo "Setting default shell to zsh..."
usermod -s /bin/zsh jovyan || { echo "Failed to change shell"; exit 1; }

echo "Installation completed successfully"
