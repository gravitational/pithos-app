# Copyright 2016 The Kubernetes Authors All rights reserved.
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

FROM quay.io/gravitational/debian-grande:0.0.1

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    KUBECTL_VERSION=1.3.8 \
    TELEGRAF_VERSION=1.1.1

COPY cassandra.list /etc/apt/sources.list.d/cassandra.list

RUN gpg --keyserver pool.sks-keyservers.net --recv-keys F758CE318D77295D && \
  gpg --export --armor F758CE318D77295D | apt-key add - && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys 2B5C1B00 && \
  gpg --export --armor 2B5C1B00 | apt-key add - && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys A278B781FE4B2BDA && \
  gpg --export --armor A278B781FE4B2BDA | apt-key add - && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys 0353B12C && \
  gpg --export --armor 0353B12C | apt-key add - && \
  apt-get update && \
  apt-get -y install -t jessie-backports ca-certificates-java openjdk-8-jre-headless && \
  apt-get -y install procps cassandra curl libjemalloc1 cron gawk && \
  curl -sSL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
  curl -sSL https://dl.influxdata.com/telegraf/releases/telegraf-${TELEGRAF_VERSION}_linux_amd64.tar.gz -o /telegraf.tar.gz && \
  tar xzf /telegraf.tar.gz --strip-components=2 && \
  rm -rf \
        doc \
        man \
        info \
        locale \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        common-licenses \
        ~/.bashrc \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/share/doc/ \
        /usr/share/doc-base/ \
        /usr/share/man/ \
        /tmp/* \
        /telegraf.tar.gz \
        /etc/telegraf/* \
        /etc/cassandra/*

ADD rootfs/ /

RUN chmod a+rx /run.sh && \
    chmod a+rx /initialize.sh && \
    chmod a+rx /usr/sbin/start-utils.sh && \
    chmod a+rx /usr/local/bin/kubectl && \
    chmod a+rx /cassandra-status.sh

RUN mkfifo --mode 0666 /var/log/cron.log

VOLUME /cassandra_data /etc/cassandra

EXPOSE 7000 7001 7011 7199 9042

RUN test -f /cleanup.sh && sh /cleanup.sh

ENTRYPOINT ["/usr/bin/dumb-init", "/run.sh"]
