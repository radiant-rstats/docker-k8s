#!/bin/bash

set -e

mamba install --quiet --yes -c conda-forge \
  c-compiler \
  "r-base>=${R_VERSION}" \
  r-systemfonts \
  r-matrix \
  r-curl \
  r-igraph \
  pandoc \
  snappy \
  cmake
mamba clean --all -f -y
 
## build ARGs
NCPUS=${NCPUS:--1}

##  mechanism to force source installs if we're using RSPM
UBUNTU_VERSION=${UBUNTU_VERSION:-`lsb_release -sc`}
CRAN=${CRAN:-https://cran.r-project.org}
CRAN_SOURCE=${CRAN/"__linux__/$UBUNTU_VERSION/"/""}

if [ "$(uname -m)" != "aarch64" ]; then
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb -O quarto.deb
    gdebi -n quarto.deb # adding -n to run non-interactively
else
    wget https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-arm64.deb -O quarto.deb
    gdebi -n quarto.deb # adding -n to run non-interactively
    CRAN=$CRAN_SOURCE
fi

# Get R packages
R -e "install.packages('quarto', repo='${CRAN}', Ncpus=${NCPUS})"

# Clean up
rm -rf quarto.deb
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages