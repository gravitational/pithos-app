#!/bin/bash
set -e

echo "Assuming changeset from the environment: $RIG_CHANGESET"
# note that rig does not take explicit changeset ID
# taking it from the environment variables
if [ $1 = "update" ]; then
    echo "Starting update, changeset: $RIG_CHANGESET"
    rig cs delete --force -c cs/$RIG_CHANGESET

    echo "Creating or updating resources"
    kubectl get configmap/pithos-cfg -o yaml > pithoscfg.yaml
    sed -i 's/localhost/cassandra.default.svc.cluster.local/' pithoscfg.yaml
    kubectl apply -f pithoscfg.yaml

    rig delete configmaps/cassandra-cfg --force
    rig delete deployments/pithos --force
    rig delete deployments/cassandra-utils --force
    rig delete daemonsets/cassandra --force

    rig upsert -f /var/lib/gravity/resources/cassandra.yaml --debug
    if [ $(kubectl get nodes -l pithos-role=node -o name | wc -l) -ge 3 ]
    then
        kubectl scale statefulset cassandra --replicas=3
    fi

    rig upsert -f /var/lib/gravity/resources/pithos.yaml --debug
    echo "Checking status"
    rig status $RIG_CHANGESET --retry-attempts=120 --retry-period=1s --debug
    echo "Updating cassandra compaction settings for storage.block column family"
    kubectl apply -f /var/lib/gravity/resources/cassandra-alter-compaction.yaml
    echo "Freezing"
    rig freeze
elif [ $1 = "rollback" ]; then
    echo "Reverting changeset $RIG_CHANGESET"
    rig revert

    kubectl get configmap/pithos-cfg -o yaml > pithoscfg.yaml
    sed -i 's/cassandra.default.svc.cluster.local/localhost/' pithoscfg.yaml
    kubectl apply -f pithoscfg.yaml

else
    echo "Missing argument, should be either 'update' or 'rollback'"
fi
