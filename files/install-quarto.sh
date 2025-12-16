#!/bin/bash

set -e

# apt update -qq || { echo "Failed to update package list"; exit 1; }
# sudo apt install lmodern
# apt clean
# apt autoremove -y
# rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# mamba install --quiet --yes -c conda-forge pandoc
# mamba clean --all -f -y

if [ "$(uname -m)" != "aarch64" ]; then
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb -O quarto.deb
    gdebi -n quarto.deb # adding -n to run non-interactively
else
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-arm64.deb -O quarto.deb
    gdebi -n quarto.deb # adding -n to run non-interactively
fi

# Clean up
rm -rf quarto.deb
rm -rf /var/lib/apt/lists/*
