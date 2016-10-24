FROM quay.io/gravitational/debian-grande:latest

RUN apt-get update && \
    apt-get -y install openjdk-7-jre-headless

RUN mkdir -p /root/cfssl
ADD *.json /root/cfssl/

ADD bin/cfssl \
    bin/cfssljson  \
    bin/pithosboot \
        /usr/local/bin/
RUN chmod a+x /usr/local/bin/cfssl*

ADD bootstrap.sh /bootstrap.sh

RUN test -f /cleanup.sh && sh /cleanup.sh
CMD ["/bootstrap.sh"]
