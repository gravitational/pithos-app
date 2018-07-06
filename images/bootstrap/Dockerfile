FROM quay.io/gravitational/debian-grande:stretch

RUN apt-get update && \
    apt-get -y install openjdk-8-jre-headless

ADD bin/pithosctl \
        /usr/local/bin/

ADD bootstrap.sh /bootstrap.sh

RUN test -f /cleanup.sh && sh /cleanup.sh
CMD ["/bootstrap.sh"]
