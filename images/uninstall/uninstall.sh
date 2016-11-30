#!/bin/sh

kubectl label nodes -l pithos-role=node pithos-role-
kubectl delete configmap cassandra-cfg pithos-cfg
kubectl delete -f /var/lib/gravity/resources/cassandra.yaml
kubectl delete -f /var/lib/gravity/resources/pithos-rc.yaml
kubectl delete secret cassandra-ssl pithos-keys
