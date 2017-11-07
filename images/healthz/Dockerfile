FROM quay.io/gravitational/debian-tall:0.0.1

ADD bin/healthz \
        /usr/local/bin/

ADD endpoint.sh /endpoint.sh
RUN chmod a+x /endpoint.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/endpoint.sh"]
