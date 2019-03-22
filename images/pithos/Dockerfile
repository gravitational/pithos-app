FROM clojure:openjdk-8-lein as builder
ARG PITHOS_VERSION=54790f00fbfd330c6196d42e5408385028d5e029
RUN apt-get update && \
    apt-get install -qq -y git && \
    git clone https://github.com/exoscale/pithos.git && \
    cd pithos && \
    git checkout $PITHOS_VERSION && \
    LEIN_SILENT=true lein uberjar

FROM quay.io/gravitational/debian-grande:stretch

COPY --from=builder /tmp/pithos/target/pithos-0.7.6-SNAPSHOT-standalone.jar /pithos.jar
ADD run.sh /run.sh
ADD aws.sh /usr/local/bin/aws.sh

RUN apt-get update && apt-get -qq -y install \
        openjdk-8-jre-headless awscli aws-shell groff curl net-tools && \
    useradd -ms /bin/bash pithos && \
    chown -R pithos /run.sh /pithos.jar && \
    chmod +x /run.sh && \
    chmod +x /usr/local/bin/aws.sh && \
    aws configure set default.s3.signature_version s3

RUN test -f /cleanup.sh && sh /cleanup.sh

CMD /run.sh
