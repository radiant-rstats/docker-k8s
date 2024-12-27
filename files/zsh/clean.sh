#!/usr/bin/env bash

## script to run from a terminal in the docker container
## to remove locally install R and python packages

HOMEDIR="/home/$(whoami)"

if [ ! -d "${HOMEDIR}/.rsm-msba" ]; then
  echo "-----------------------------------------------------"
  echo "Directory ${HOMEDIR}/.rsm-msba not found"
  echo "No cleanup done"
  echo "-----------------------------------------------------"
else
  echo "-----------------------------------------------------"
  echo "Remove locally installed R packages (y/n)?"
  echo "-----------------------------------------------------"
  read cleanup

  if [ "${cleanup}" == "y" ]; then
    echo "Removing locally installed R packages"
    rm_list=$(ls -d "${HOMEDIR}"/.rsm-msba/R/[0-9]\.[0-9]\.[0-9] 2>/dev/null)
    for i in ${rm_list}; do
      rm -rf "${i}"
      mkdir "${i}"
    done
  fi

  echo "-----------------------------------------------------"
  echo "Remove locally installed Python packages (y/n)?"
  echo "-----------------------------------------------------"
  read cleanup

  if [ "${cleanup}" == "y" ]; then
    echo "Removing locally installed Python packages"
    rm -rf "${HOMEDIR}/.rsm-msba/bin"
    rm -rf "${HOMEDIR}/.rsm-msba/lib"
    rm_list=$(ls "${HOMEDIR}/.rsm-msba/share" | grep -v jupyter)
    for i in ${rm_list}; do
       rm -rf "${HOMEDIR}/.rsm-msba/share/${i}"
    done
  fi

  echo "-----------------------------------------------------"
  echo "Cleanup complete"
  echo "-----------------------------------------------------"
fi
