#!/bin/bash
set -e

echo "Assuming changeset from the environment: $RIG_CHANGESET"
# note that rig does not take explicit changeset ID
# taking it from the environment variables
if [ $1 = "update" ]; then
    echo "Starting update, changeset: $RIG_CHANGESET"
    rig cs delete --force -c cs/$RIG_CHANGESET

    echo "Creating or updating resources"
    kubectl delete configmap/cassandra-cfg
    kubectl create configmap cassandra-cfg --from-file=/var/lib/gravity/resources/cassandra-cfg
    rig delete rc/pithos --force

    rig upsert -f /var/lib/gravity/resources/cassandra.yaml --debug
    rig upsert -f /var/lib/gravity/resources/pithos.yaml --debug
    echo "Checking status"
    rig status $RIG_CHANGESET --retry-attempts=120 --retry-period=1s --debug
    echo "Freezing"
    rig freeze
elif [ $1 = "rollback" ]; then
    echo "Reverting changeset $RIG_CHANGESET"
    rig revert

    kubectl get ds/cassandra -o yaml > /tmp/cassandra-ds.yaml
    if ! grep -q 'CASSANDRA_CLUSTER_NAME' /tmp/cassandra-ds.yaml
    then
        echo "Set CASSANDRA_CLUSTER_NAME env variable"
        sed -i '0,/env:/s//env:\n        - name: CASSANDRA_CLUSTER_NAME\n          value: Pithos Cluster/' /tmp/cassandra-ds.yaml
        kubectl replace -f /tmp/cassandra-ds.yaml
        # Hack, because of "https://github.com/kubernetes/kubernetes/issues/29199"
        kubectl delete po -l 'pithos-role=cassandra'
    fi
else
    echo "Missing argument, should be either 'update' or 'rollback'"
fi
