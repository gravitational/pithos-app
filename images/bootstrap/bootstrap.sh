#!/bin/sh

cd /root/cfssl

cfssl gencert -initca ca-csr.json|cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | cfssljson -bare server

kubectl create secret generic pithos-ca --from-file=ca.pem=ca.pem --from-file=ca-key=ca-key.pem --from-file=ca-config.json=ca-config.json --from-file=ca-csr.json=ca-csr.json --from-file=ca.csr=ca.csr
kubectl create secret generic pithos-ssl --from-file=server-csr.json=server-csr.json --from-file=server-key.pem=server-key.pem --from-file=server.csr=server.csr --from-file=server.pem=server.pem

/pithosboot

