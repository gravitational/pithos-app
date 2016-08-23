FROM quay.io/gravitational/debian-tall:latest

RUN mkdir -p /root/cfssl
ADD *.json /root/cfssl/

ADD bin/cfssl \
    bin/cfssljson  \
    bin/pithosboot \
        /usr/local/bin/
RUN chmod a+x /usr/local/bin/cfssl*

ADD bootstrap.sh /bootstrap.sh
CMD ["/bootstrap.sh"]
