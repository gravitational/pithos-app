#!/usr/bin/env bash

NUM_NODES=$(kubectl get nodes --selector=pithos-role=node --no-headers | wc --lines)
REPLICATION_FACTOR=1

if [[ $NUM_NODES -gt 2 ]]; then
	REPLICATION_FACTOR=3
fi

sed 's/REPLICATION_FACTOR/'"${REPLICATION_FACTOR}"'/g' /init.cql > /tmp/init.cql
cat /tmp/init.cql > /init.cql # avoid issues with sed and writing in /

cqlsh -f /init.cql cassandra.default.svc.cluster.local
