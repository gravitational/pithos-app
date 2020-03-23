FROM clojure:openjdk-8-lein as builder
ARG PITHOS_VERSION=aac875cae82281ffb9a89395e5ba10d586372dbc
RUN apt-get update && \
    apt-get install -qq -y git && \
    git clone https://github.com/gravitational/pithos.git && \
    cd pithos && \
    git checkout $PITHOS_VERSION && \
    LEIN_SILENT=true lein uberjar

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive

ADD run.sh /run.sh
ADD aws.sh /usr/local/bin/aws.sh

RUN apt-get update && apt-get -qq -y install \
        openjdk-8-jre-headless awscli aws-shell groff curl net-tools dumb-init && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -ms /bin/bash pithos && \
    chown -R pithos /run.sh && \
    chmod +x /run.sh && \
    chmod +x /usr/local/bin/aws.sh && \
    aws configure set default.s3.signature_version s3

COPY --from=builder /tmp/pithos/target/pithos-0.7.6-SNAPSHOT-standalone.jar /pithos.jar
RUN chown pithos /pithos.jar

CMD /run.sh
