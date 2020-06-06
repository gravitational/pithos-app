#!/usr/bin/env bash

set -o nounset
set -o errexit

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export PASSWORD_FOR_JAVA_TRUSTSTORE='changeit'
export MAX_HEAP_SIZE=${MAX_HEAP_SIZE:-1024M}
export JVM_OPTS="-XX:+UseG1GC -Xms${MAX_HEAP_SIZE} -Xmx${MAX_HEAP_SIZE}"

keytool -import -trustcacerts -keystore ${JAVA_HOME}/lib/security/cacerts -alias cassandra-node -import -file ${CASSANDRA_CERT_FILE} -storepass ${PASSWORD_FOR_JAVA_TRUSTSTORE} -noprompt || true

dumb-init java ${JVM_OPTS} -jar /pithos.jar -f /etc/pithos/config.yaml
