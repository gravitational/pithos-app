#!/usr/bin/env bash

NUM_NODES=$(kubectl get nodes --selector=pithos-role=node --no-headers | wc --lines)
REPLICATION_FACTOR=1

if [[ $NUM_NODES -gt 2 ]]; then
	REPLICATION_FACTOR=3
fi

sed -i 's/REPLICATION_FACTOR/'"${REPLICATION_FACTOR}"'/g' /init.cql

cqlsh -f /init.cql cassandra.default.svc
