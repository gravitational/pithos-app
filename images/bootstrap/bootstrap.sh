#!/bin/sh

## generate cassandra specific keys

keytool -genkey \
	-keyalg RSA \
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

kubectl create secret generic cassandra-ssl \
	--from-file=cassandra-node.cer=cassandra-node.cer \
	--from-file=keystore=keystore \
	--from-file=sbx.truststore=sbx.truststore \
    --from-file=cassandra-node.pem=cassandra-node.pem

pithosboot

if [ $(/opt/bin/kubectl get nodes -l pithos-role=node -o name | wc -l) -ge 3 ]
then
    /opt/bin/kubectl scale statefulset cassandra --replicas=3
fi

/opt/bin/kubectl create -f /var/lib/gravity/resources/monitoring.yaml
