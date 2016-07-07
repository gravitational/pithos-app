#!/bin/sh

kubectl label nodes -l role=node pithos-role=node
kubectl create configmap cassandra-cfg --from-file=/var/lib/gravity/resources/cassandra-cfg
kubectl create configmap pithos-cfg --from-file=/var/lib/gravity/resources/pithos-cfg
kubectl create -f /var/lib/gravity/resources/pithos.yaml
