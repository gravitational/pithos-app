FROM quay.io/gravitational/debian-grande:buster

ADD bin/pithosctl /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/pithosctl", "server"]
