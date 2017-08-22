#!/bin/bash
set -e

echo "Assuming changeset from the environment: $RIG_CHANGESET"
# note that rig does not take explicit changeset ID
# taking it from the environment variables
if [ $1 = "update" ]; then
    echo "Starting update, changeset: $RIG_CHANGESET"
    rig cs delete --force -c cs/$RIG_CHANGESET

    echo "Creating or updating resources"
    CASSANDRA_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 | tr -d '\n')
    if ! $(kubectl get secret/cassandra-password >> /dev/null)
    then
        cat <<EOF > cassandra-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cassandra-password
  namespace: default
type: Opaque
data:
  cassandra: $(echo $CASSANDRA_PASSWORD | base64)
EOF
        kubectl create -f cassandra-secret.yaml
    fi

    kubectl get configmap/pithos-cfg -o yaml > pithoscfg.yaml
    sed -i 's/localhost/cassandra.default.svc.cluster.local/' pithoscfg.yaml
    if ! $(grep 'password' pithoscfg.yaml >> /dev/null)
    then
        sed -i -r "s/^(\s*)(cluster.*$)/\1\2\n\1username: 'cassandra'\n\1password: '${CASSANDRA_PASSWORD}'/" pithoscfg.yaml
    fi
    kubectl apply -f pithoscfg.yaml

    kubectl delete configmap/cassandra-cfg
    kubectl create configmap cassandra-cfg --from-file=/var/lib/gravity/resources/cassandra-cfg
    rig delete deployments/pithos --force

    rig upsert -f /var/lib/gravity/resources/cassandra.yaml --debug
    rig upsert -f /var/lib/gravity/resources/cassandra-password.yaml --debug
    rig upsert -f /var/lib/gravity/resources/pithos.yaml --debug
    echo "Checking status"
    rig status $RIG_CHANGESET --retry-attempts=120 --retry-period=1s --debug
    echo "Freezing"
    rig freeze
elif [ $1 = "rollback" ]; then
    echo "Reverting changeset $RIG_CHANGESET"
    rig revert

    kubectl get configmap/pithos-cfg -o yaml > pithoscfg.yaml
    sed -i 's/localhost/cassandra.default.svc.cluster.local/' pithoscfg.yaml
    kubectl apply -f pithoscfg.yaml

else
    echo "Missing argument, should be either 'update' or 'rollback'"
fi
