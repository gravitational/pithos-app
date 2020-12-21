#!/usr/bin/env bash

set -o errexit
set -o nounset

## generate cassandra specific keys

keytool -genkey \
	-keyalg RSA \
	-validity 3650 \
	-alias cassandra-node \
	-keystore keystore \
	-storepass cassandra \
	-dname "CN=cassandra-node, O=Gravitational, C=US" \
	-keypass cassandra

keytool -export \
	-alias cassandra-node \
	-file cassandra-node.cer \
	-keystore keystore \
	-storepass cassandra

yes | keytool -import \
	-trustcacerts \
	-alias cassandra-node \
	-file cassandra-node.cer \
	-keystore sbx.truststore \
	-storepass cassandra

keytool -importkeystore \
	-srckeystore keystore \
	-srcstorepass cassandra \
	-destkeystore cassandra-node.p12 \
	-deststoretype PKCS12 \
	-deststorepass cassandra

openssl pkcs12 \
	-in cassandra-node.p12 \
	-out cassandra-node.pem \
	-password pass:cassandra \
	-nodes

if ! kubectl get secret cassandra-ssl > /dev/null 2>&1
then
    kubectl create secret generic cassandra-ssl \
	        --from-file=cassandra-node.cer=cassandra-node.cer \
	        --from-file=keystore=keystore \
	        --from-file=sbx.truststore=sbx.truststore \
	        --from-file=cassandra-node.pem=cassandra-node.pem
fi

if [ $(/opt/bin/kubectl get nodes -l pithos-role=node -o name | wc -l) -ge 3 ]
then
    sed -i 's/replicas: 1/replicas: 3/' /var/lib/gravity/resources/cassandra.yaml
fi

pithosctl init

/opt/bin/kubectl apply -f /var/lib/gravity/resources/pithosctl.yaml
# temporarely disable alerts until we adapt them to prometheus
# /opt/bin/gravity resource create -f /var/lib/gravity/resources/alerts.yaml
