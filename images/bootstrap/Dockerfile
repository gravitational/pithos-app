FROM quay.io/gravitational/debian-tall:latest

ADD pithosboot /pithosboot
ADD bootstrap.sh /bootstrap.sh

RUN mkdir -p /root/cfssl
ADD *.json /root/cfssl/

ADD https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 /usr/local/bin/cfssl
ADD https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 /usr/local/bin/cfssljson

RUN chmod a+x /usr/local/bin/cfssl*

CMD ["/bootstrap.sh"]
