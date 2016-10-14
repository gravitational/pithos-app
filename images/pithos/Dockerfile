FROM quay.io/gravitational/debian-grande:0.0.1

ADD pithos.jar /pithos.jar
ADD run.sh /run.sh
ADD initialize.sh /initialize.sh
ADD init.cql /init.cql

RUN apt-get update && apt-get -qq -y install openjdk-7-jre-headless && \
    useradd -ms /bin/bash pithos && \
    chown -R pithos /run.sh /pithos.jar && \
    chmod +x /run.sh && \
    chmod +x /initialize.sh

RUN test -f /cleanup.sh && sh /cleanup.sh

CMD /run.sh
