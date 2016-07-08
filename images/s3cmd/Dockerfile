FROM quay.io/gravitational/debian-grande:0.0.1

RUN apt-get update && \
  apt-get -qq -y install s3cmd vim

RUN test -f /cleanup.sh && sh /cleanup.sh
