#!/bin/bash
set -e

echo "Assuming changeset from the environment: $RIG_CHANGESET"
# note that rig does not take explicit changeset ID
# taking it from the environment variables
if [ $1 = "update" ]; then
    echo "Starting update, changeset: $RIG_CHANGESET"
    rig cs delete --force -c cs/$RIG_CHANGESET

    echo "Creating or updating resources"
    rig delete configmaps/cassandra-cfg --force
    rig delete deployments/pithos --force
    rig delete deployments/cassandra-utils --force
    rig delete daemonsets/cassandra --force
    rig delete configmaps/rollups-pithos --resource-namespace=monitoring --force
    rig delete configmaps/pithos-alerts --resource-namespace=monitoring --force
    rig delete configmaps/cassandra --force
    rig delete configmaps/pithos-cfg --force
    rig delete jobs/cassandra-alter-compaction --force

    # update `pithos-cfg` configmap
    /usr/local/bin/pithosctl update

    rig upsert -f /var/lib/gravity/resources/cassandra.yaml --debug
    if [ $(kubectl get nodes -l pithos-role=node -o name | wc -l) -ge 3 ]
    then
        kubectl scale statefulset cassandra --replicas=3
    fi

    rig upsert -f /var/lib/gravity/resources/pithos.yaml --debug
    # temporarely disable alerts until we adapt them to prometheus
    # /opt/bin/gravity resource create -f /var/lib/gravity/resources/alerts.yaml

    echo "Checking status"
    rig status $RIG_CHANGESET --retry-attempts=120 --retry-period=2s --debug
    echo "Updating cassandra compaction settings for storage.block column family"
    rig upsert -f /var/lib/gravity/resources/cassandra-alter-compaction.yaml
    echo "Checking status after applying the job"
    rig status $RIG_CHANGESET --retry-attempts=120 --retry-period=2s --debug
    echo "Freezing"
    rig freeze
elif [ $1 = "rollback" ]; then
    echo "Reverting changeset $RIG_CHANGESET"
    rig revert
else
    echo "Missing argument, should be either 'update' or 'rollback'"
fi
