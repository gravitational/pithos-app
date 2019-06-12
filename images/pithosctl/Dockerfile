FROM quay.io/gravitational/debian-grande:stretch

ADD bin/pithosctl /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/pithosctl", "server"]
