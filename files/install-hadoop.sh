#!/bin/bash
set -e

if [ ! -d "${HADOOP_HOME}" ]; then
  mkdir $HADOOP_HOME
fi

apt update -qq && apt -y --no-install-recommends install \
  openjdk-17-jdk-headless \
  ca-certificates-java \
  ant

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x --strip-components=1 -C $HADOOP_HOME && \
  rm -rf $HADOOP_HOME/share/doc && \
  ln -s /opt/hadoop/bin/hadoop /usr/bin/hadoop && \
  chown -R ${NB_USER} $HADOOP_HOME && \
  mkdir -p "${HADOOP_HOME}/logs"
