FROM quay.io/gravitational/rig:7.0.2

ARG CHANGESET
ENV RIG_CHANGESET $CHANGESET

ADD entrypoint.sh /
ADD bin/pithosctl /usr/local/bin/

ENTRYPOINT ["dumb-init", "/entrypoint.sh"]
