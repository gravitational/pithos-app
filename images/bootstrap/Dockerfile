FROM ubuntu:bionic

RUN apt-get update && \
    apt-get -y install openjdk-8-jre-headless && \
    rm -rf /var/lib/apt/lists/*

ADD bin/pithosctl \
        /usr/local/bin/

ADD bootstrap.sh /bootstrap.sh

CMD ["/bootstrap.sh"]
