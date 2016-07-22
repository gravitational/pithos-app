FROM quay.io/gravitational/debian-tall:latest

ADD pithosboot /pithosboot
ADD bootstrap.sh /bootstrap.sh

ADD https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 /usr/local/bin/cfssl
ADD https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 /usr/local/bin/cfssljson

CMD ["/bootstrap.sh"]
