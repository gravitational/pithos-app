#!/usr/bin/env bash

NUM_NODES=$(kubectl get nodes --selector=pithos-role=node --no-headers | wc --lines)
REPLICATION_FACTOR=1

if [[ $NUM_NODES -gt 2 ]]; then
	REPLICATION_FACTOR=3
fi

sed -i 's/REPLICATION_FACTOR/'"${REPLICATION_FACTOR}"'/g' /init.cql

if ! cqlsh cassandra.default.svc.cluster.local -k storage -e "select * from storage.block"; then
    cqlsh -f /init.cql cassandra.default.svc.cluster.local
fi
