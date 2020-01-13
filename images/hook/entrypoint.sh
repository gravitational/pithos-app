#!/bin/bash
set -e

# Check cluster state before starting upgrade
kubectl patch statefulset cassandra --type=json -p='[{"op": "remove", "path": "/spec/template/spec/containers/2"}]' || true
kubectl delete pod -lcomponent=cassandra
kubectl delete -f /var/lib/gravity/resources/preUpdate.yaml --ignore-not-found
kubectl create -f /var/lib/gravity/resources/preUpdate.yaml
kubectl wait --for=condition=complete --timeout=120s job/pithos-app-pre-update

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

    ## copy telegraf secret from monitoring namespace
    if kubectl --namespace=monitoring get secret telegraf-influxdb-creds >/dev/null 2>&1;
    then
      kubectl --namespace=monitoring get secret telegraf-influxdb-creds --export -o yaml |\
        kubectl --namespace=default apply -f -
    else
      kubectl --namespace=default apply -f /var/lib/gravity/resources/secrets.yaml
    fi

    rig upsert -f /var/lib/gravity/resources/cassandra.yaml --debug
    if [ $(kubectl get nodes -l pithos-role=node -o name | wc -l) -ge 3 ]
    then
        kubectl scale statefulset cassandra --replicas=3
    fi

    rig upsert -f /var/lib/gravity/resources/pithos.yaml --debug
    rig upsert -f /var/lib/gravity/resources/monitoring.yaml --debug
    /opt/bin/gravity resource create -f /var/lib/gravity/resources/alerts.yaml

    echo "Checking status"
    rig status $RIG_CHANGESET --retry-attempts=120 --retry-period=2s --debug
    echo "Updating cassandra compaction settings for storage.block column family"
    kubectl apply -f /var/lib/gravity/resources/cassandra-alter-compaction.yaml
    echo "Freezing"
    rig freeze
elif [ $1 = "rollback" ]; then
    echo "Reverting changeset $RIG_CHANGESET"
    rig revert
else
    echo "Missing argument, should be either 'update' or 'rollback'"
fi
