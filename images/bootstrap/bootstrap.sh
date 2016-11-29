#!/bin/sh

cd /root/cfssl

if kubectl get secret/cluster-ca ; then
    echo "secret/cluster-ca already exists"
else
    cfssl gencert -initca ca-csr.json|cfssljson -bare ca -

    kubectl create secret generic cluster-ca \
        --from-file=ca.pem=ca.pem \
        --from-file=ca-key=ca-key.pem \
        --from-file=ca.csr=ca.csr
fi

if kubectl get secret/cluster-default-ssl ; then
    echo "secret/cluster-ca already exists"
else
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
        -profile=server default-server-csr.json | cfssljson -bare default-server
    cp default-server.pem default-server-with-chain.pem
    cat ca.pem >> default-server-with-chain.pem

    kubectl create secret generic cluster-default-ssl \
        --from-file=default-server.pem=default-server.pem \
        --from-file=default-server-with-chain.pem=default-server-with-chain.pem \
        --from-file=default-server-key.pem=default-server-key.pem \
        --from-file=default-server.csr=default-server.csr
fi

if kubectl get secret/cluster-kube-system-ssl ; then
    echo "secret/cluster-kube-system-ssl already exists"
else
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
        -profile=server kube-system-server-csr.json | cfssljson -bare kube-system-server
    cp kube-system-server.pem kube-system-server-with-chain.pem
    cat ca.pem >> kube-system-server-with-chain.pem

    kubectl create secret generic cluster-kube-system-ssl \
        --from-file=default-server.pem=default-server.pem \
        --from-file=kube-system-server-with-chain.pem=kube-system-server-with-chain.pem \
        --from-file=default-server-key.pem=default-server-key.pem \
        --from-file=default-server.csr=default-server.csr
fi

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
