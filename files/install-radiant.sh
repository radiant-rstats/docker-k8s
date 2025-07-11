#!/bin/bash
set -e

UBUNTU_VERSION=${UBUNTU_VERSION:-`lsb_release -sc`}
CRAN=${CRAN:-https://cran.r-project.org}

##  mechanism to force source installs if we're using RSPM
CRAN_SOURCE=${CRAN/"__linux__/$UBUNTU_VERSION/"/""}

## source install if using RSPM and arm64 image
if [ "$(uname -m)" = "aarch64" ]; then
  CRAN=https://cran.r-project.org
  CRAN_SOURCE=${CRAN/"__linux__/$UBUNTU_VERSION/"/""}
  CRAN=$CRAN_SOURCE
fi

NCPUS=${NCPUS:--1}


# mamba install --yes -c conda-forge pyarrow=${PYARROW_VERSION} libgit2 sqlite libxml2 xz

R  -e "install.packages(c('shiny', 'png', 'miniUI', 'webshot'), repo='${CRAN}', Ncpus=${NCPUS})" \
  -e "install.packages(c('remotes'), repo='${CRAN}', Ncpus=${NCPUS})" \
  -e "Sys.setenv(ARROW_PARQUET = 'ON', ARROW_WITH_SNAPPY = 'ON', ARROW_R_DEV = TRUE); remotes::install_version('arrow', version='${PYARROW_VERSION}', repos='${CRAN}', Ncpus=${NCPUS})" \
  -e "install.packages(c('radiant'), repo='${CRAN}', Ncpus=${NCPUS})" \
  -e "remotes::install_github('radiant-rstats/radiant.update', upgrade = 'never')" \
  -e "remotes::install_github('radiant-rstats/radiant.data', upgrade = 'never')" \
  -e "remotes::install_github('radiant-rstats/radiant.design', upgrade = 'never')" \
  -e "remotes::install_github('radiant-rstats/radiant.basics', upgrade = 'never')" \
  -e "remotes::install_github('radiant-rstats/radiant.model', upgrade = 'never')" \
  -e "remotes::install_github('radiant-rstats/radiant.multivariate', upgrade = 'never')" \
  -e "remotes::install_github('radiant-rstats/radiant', upgrade = 'never')" \
  -e "webshot::install_phantomjs()"

# setup location of user installed R packages
echo "R_LIBS_USER='~/.rsm-msba/R/${R_VERSION}'" >> ${R_HOME}/etc/Renviron.site
echo '.libPaths(unique(c(Sys.getenv("R_LIBS_USER"), .libPaths())))' >> ${R_HOME}/etc/Rprofile.site

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages
rm -rf /tmp/*
rm -rf /var/tmp/*
