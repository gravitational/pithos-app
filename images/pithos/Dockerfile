FROM quay.io/gravitational/debian-grande:stretch

ADD pithos-0.7.5-standalone.jar /pithos.jar
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
