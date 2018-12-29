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
    TELEGRAF_VERSION=1.1.1

COPY cassandra.list /etc/apt/sources.list.d/cassandra.list

RUN for key in F758CE318D77295D 2B5C1B00 A278B781FE4B2BDA 0353B12C; \
    do \
      gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
      gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
      gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
      gpg --export --armor $key | apt-key add - ; \
    done

RUN apt-get update && \
  apt-get -y install curl && \
  # Install older version of OpenJDK
  # https://stackoverflow.com/questions/48328661/cant-start-cassandra-after-os-patch-up
  curl -sSL http://snapshot.debian.org/archive/debian/20170515T212805Z/pool/main/o/openjdk-8/openjdk-8-jre-headless_8u131-b11-1~bpo8%2B1_amd64.deb -o openjdk-8-jre-headless_8u131-b11-1~bpo8+1_amd64.deb && \
  dpkg -i openjdk-8-jre-headless_8u131-b11-1~bpo8+1_amd64.deb || true && \
  apt-mark hold openjdk-8-jre-headless && \
  apt-get -y install -t jessie-backports -f && \
  apt-get -y install procps cassandra libjemalloc1 cron gawk && \
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
        /openjdk-8-jre-headless_8u151-b12-1_amd64.deb \
        /etc/telegraf/* \
        /etc/cassandra/*

ADD rootfs/ /

RUN chmod a+rx /run.sh && \
    chmod a+rx /initialize.sh && \
    chmod a+rx /usr/sbin/start-utils.sh && \
    chmod a+rx /cassandra-status.sh

RUN mkfifo --mode 0666 /var/log/cron.log

VOLUME /cassandra_data /etc/cassandra

EXPOSE 7000 7001 7011 7199 9042

RUN test -f /cleanup.sh && sh /cleanup.sh

ENTRYPOINT ["/usr/bin/dumb-init", "/run.sh"]
