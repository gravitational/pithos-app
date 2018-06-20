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

FROM quay.io/gravitational/debian-grande:stretch

ARG CASSANDRA_VERSION
ARG JOLOKIA_VERSION
ARG TELEGRAF_VERSION

ENV TERM=xterm \
    CASSANDRA_HOME=/usr/local/apache-cassandra-${CASSANDRA_VERSION} \
    CASSANDRA_CONF=/etc/cassandra \
    CASSANDRA_DATA=/cassandra_data \
    CASSANDRA_LOGS=/var/log/cassandra \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PATH=${PATH}:/usr/lib/jvm/java-8-openjdk-amd64/bin:/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin

ADD rootfs/ /

RUN /build.sh && rm /build.sh
RUN mkfifo --mode 0666 /var/log/cron.log

VOLUME ["/$CASSANDRA_DATA"]

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

RUN test -f /cleanup.sh && sh /cleanup.sh && rm /cleanup.sh

ENTRYPOINT ["/usr/bin/dumb-init", "/bin/bash", "/run.sh"]
