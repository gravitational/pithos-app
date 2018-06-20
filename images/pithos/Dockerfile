FROM quay.io/gravitational/debian-grande:stretch

ADD pithos-0.7.5-standalone.jar /pithos.jar
ADD run.sh /run.sh

RUN apt-get update && apt-get -qq -y install openjdk-8-jre-headless && \
    useradd -ms /bin/bash pithos && \
    chown -R pithos /run.sh /pithos.jar && \
    chmod +x /run.sh

RUN apt-get -qq -y install curl net-tools
RUN test -f /cleanup.sh && sh /cleanup.sh

CMD /run.sh
