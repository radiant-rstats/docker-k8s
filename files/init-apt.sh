echo "Installing packages that are needed for all next steps"
apt update -qq
apt -y --no-install-recommends install \
  sudo \
  curl \
  lsb-release \
  zsh \
  vim \
  vifm \
  wget \
  rsync \
  git \
  htop \
  lsof \
  rename \
  pipx

echo "Cleaning up..."
apt clean
update-ca-certificates -f
rm -rf /var/lib/apt/lists/*
