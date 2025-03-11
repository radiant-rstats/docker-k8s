#!/usr/bin/env bash

if [ ! -f extensions.txt ]; then
  wget https://raw.githubusercontent.com/radiant-rstats/docker-k8s/main/vscode/extensions.txt
fi

cat extensions.txt | while read extension || [[ -n $extension ]];
do
  code --install-extension $extension --force
done