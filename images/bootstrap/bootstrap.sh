#!/bin/sh

cd /root/cfssl

cfssl gencert -initca ca-csr.json|cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server default-server-csr.json | cfssljson -bare default-server

kubectl create secret generic cluster-ca \
   --from-file=ca.pem=ca.pem \
   --from-file=ca-key=ca-key.pem \
   --from-file=ca.csr=ca.csr

kubectl create secret generic cluster-default-ssl \
	--from-file=default-server.pem=default-server.pem \
	--from-file=default-server-key.pem=default-server-key.pem \
	--from-file=default-server.csr=default-server.csr

pithosboot
