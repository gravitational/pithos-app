FROM quay.io/gravitational/debian-tall:0.0.1

ADD bin/healthz /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/healthz", "-access-key-id", "${AWS_ACCESS_KEY_ID}", \
    "-secret-access-key", "${AWS_SECRET_ACCESS_KEY}"]
