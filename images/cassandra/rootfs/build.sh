#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -o errexit
set -o nounset
set -o pipefail

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

apt-get update

apt-get install -y \
    openjdk-8-jre-headless \
    libjemalloc1 \
    cron \
    curl \
    gawk \
    python \
    jq \
    dumb-init

CASSANDRA_PATH="cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz"
CASSANDRA_DOWNLOAD="http://www.apache.org/dyn/closer.cgi?path=/${CASSANDRA_PATH}&as_json=1"
CASSANDRA_MIRROR=`curl -L ${CASSANDRA_DOWNLOAD} | grep -oP "(?<=\"preferred\": \")[^\"]+"`

echo "Downloading Apache Cassandra from $CASSANDRA_MIRROR$CASSANDRA_PATH..."
curl -L $CASSANDRA_MIRROR$CASSANDRA_PATH \
    | tar -xzf - -C /usr/local

mkdir -p /cassandra_data/data
mkdir -p /etc/cassandra

mv /usr/local/apache-cassandra-${CASSANDRA_VERSION}/conf/cassandra-env.sh /etc/cassandra/

adduser --disabled-password --no-create-home --gecos '' --disabled-login cassandra
chmod +x /ready-probe.sh
chown cassandra: /ready-probe.sh
chown -R cassandra: /etc/cassandra

mv /kubernetes-cassandra.jar /usr/local/apache-cassandra-${CASSANDRA_VERSION}/lib

echo "Downloading and installing jolokia agent..."
curl -L https://github.com/rhuss/jolokia/releases/download/v${JOLOKIA_VERSION}/jolokia-${JOLOKIA_VERSION}-bin.tar.gz | tar -xzf - -C /tmp
cp /tmp/jolokia-${JOLOKIA_VERSION}/agents/jolokia-jvm.jar /usr/local/apache-cassandra-${CASSANDRA_VERSION}/lib

echo "Downloading and installing telegraf..."
curl -L https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_amd64.tar.gz | tar -xzf - --strip-components=2 -C / ./telegraf/usr/bin/telegraf
adduser --disabled-password --no-create-home --gecos '' --disabled-login telegraf
chown telegraf: /usr/bin/telegraf
chown -R telegraf: /etc/telegraf

echo "Dwonloading jmxterm..."
curl -L https://sourceforge.net/projects/cyclops-group/files/jmxterm/1.0.0/jmxterm-1.0.0-uber.jar/download -o /jmxterm.jar

rm -rf \
    $CASSANDRA_HOME/*.txt \
    $CASSANDRA_HOME/doc \
    $CASSANDRA_HOME/javadoc \
    $CASSANDRA_HOME/tools/*.yaml \
    $CASSANDRA_HOME/tools/bin/*.bat \
    $CASSANDRA_HOME/bin/*.bat \
    doc \
    man \
    info \
    locale \
    common-licenses \
    ~/.bashrc \
    /var/log/* \
    /var/cache/debconf/* \
    /etc/systemd \
    /lib/lsb \
    /lib/udev \
    /usr/share/doc-base/ \
    /tmp/* \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/plugin \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/javaws \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/jjs \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/orbd \
    /usr/lib/jvm/java-8-openjdk-amd64/bin/pack200 \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/policytool \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/rmid \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/rmiregistry \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/servertool \
    /usr/lib/jvm/java-8-openjdk-amd64/bin/tnameserv \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/unpack200 \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/javaws.jar \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/deploy* \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/desktop \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/*javafx* \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/*jfx* \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libdecora_sse.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libprism_*.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libfxplugins.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libglass.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libgstreamer-lite.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libjavafx*.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/libjfx*.so \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/jfxrt.jar \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/nashorn.jar \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/oblique-fonts \
    /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/plugin.jar \
    /usr/lib/jvm/java-8-openjdk-amd64/man \
    /var/lib/apt/lists/*

