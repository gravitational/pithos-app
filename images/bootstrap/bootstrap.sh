#!/bin/sh

mkdir -p /etc/ssl && cd /etc/ssl

cfssl gencert -initca ca-csr.json|cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | cfssljson -bare server

/pithosboot
