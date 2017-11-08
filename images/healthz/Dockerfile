FROM quay.io/gravitational/debian-tall:0.0.1

ADD bin/healthz \
        /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
