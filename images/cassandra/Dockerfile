FROM maven:3-jdk-8-alpine as builder
WORKDIR /usr/src/app
COPY java/ .
RUN mvn -q clean package

FROM ubuntu:bionic

ARG CASSANDRA_VERSION
ARG JOLOKIA_VERSION
ARG TELEGRAF_VERSION

ENV TERM=xterm \
    CASSANDRA_HOME=/usr/local/apache-cassandra-${CASSANDRA_VERSION} \
    CASSANDRA_CONF=/etc/cassandra \
    CASSANDRA_DATA=/cassandra_data \
    CASSANDRA_LOGS=/var/log/cassandra \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PATH=${PATH}:/usr/lib/jvm/java-8-openjdk-amd64/bin:/usr/local/apache-cassandra-${CASSANDRA_VERSION}/bin:/usr/local/apache-cassandra-${CASSANDRA_VERSION}/tools/bin

ADD rootfs/ /
COPY --from=builder /usr/src/app/target/*jar-with-dependencies.jar /kubernetes-cassandra.jar

RUN /build.sh && rm /build.sh
RUN mkfifo --mode 0666 /var/log/cron.log

VOLUME ["/$CASSANDRA_DATA"]
USER cassandra

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

ENTRYPOINT ["/usr/bin/dumb-init", "/bin/bash", "/run.sh"]
