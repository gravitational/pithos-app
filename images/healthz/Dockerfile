FROM quay.io/gravitational/debian-tall:stretch

ADD bin/pithosctl /usr/local/bin/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD /usr/local/bin/pithosctl healthz --access-key-id ${AWS_ACCESS_KEY_ID} \
    --secret-access-key ${AWS_SECRET_ACCESS_KEY}
