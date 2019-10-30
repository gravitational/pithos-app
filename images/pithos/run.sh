#!/usr/bin/env bash

set -o nounset
set -o errexit

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export PASSWORD_FOR_JAVA_TRUSTSTORE='changeit'

keytool -import -trustcacerts -keystore ${JAVA_HOME}/lib/security/cacerts -alias cassandra-node -import -file ${CASSANDRA_CERT_FILE} -storepass ${PASSWORD_FOR_JAVA_TRUSTSTORE} -noprompt || true

dumb-init java -jar /pithos.jar -f /etc/pithos/config.yaml
