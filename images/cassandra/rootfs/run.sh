#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CONF_DIR=/etc/cassandra
CONF_DIR_RO=/etc/cassandra-ro
CFG=$CONF_DIR/cassandra.yaml

CASSANDRA_RPC_ADDRESS="${CASSANDRA_RPC_ADDRESS:-0.0.0.0}"
CASSANDRA_NUM_TOKENS="${CASSANDRA_NUM_TOKENS:-32}"
CASSANDRA_CLUSTER_NAME="${CASSANDRA_CLUSTER_NAME:='Pithos Cluster'}"
CASSANDRA_LISTEN_ADDRESS=${POD_IP}
CASSANDRA_BROADCAST_ADDRESS=${POD_IP}
CASSANDRA_BROADCAST_RPC_ADDRESS=${POD_IP}

CASSANDRA_OPEN_JMX=false

# Replace content of /etc/cassandra directory with content from ConfigMap
rm -rf $CONF_DIR/*
cp -aL $CONF_DIR_RO/* $CONF_DIR/
chmod +w -R $CONF_DIR/*

# TODO what else needs to be modified

for yaml in \
  broadcast_address \
	broadcast_rpc_address \
	cluster_name \
	listen_address \
	num_tokens \
	rpc_address \
; do
  var="CASSANDRA_${yaml^^}"
	val="${!var}"
	if [ "$val" ]; then
		sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$CFG"
	fi
done

# Eventual do snitch $DC && $RACK?
#if [[ $SNITCH ]]; then
#  sed -i -e "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: $SNITCH/" $CONFIG/cassandra.yaml
#fi
#if [[ $DC && $RACK ]]; then
#  echo "dc=$DC" > $CONFIG/cassandra-rackdc.properties
#  echo "rack=$RACK" >> $CONFIG/cassandra-rackdc.properties
#fi

sed -ri 's/- seeds:.*/- seeds: "'"$POD_IP"'"/' $CFG

#
# see if this is needed
echo "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=$POD_IP\"" >> $CONF_DIR/cassandra-env.sh
echo "JVM_OPTS=\"\$JVM_OPTS -javaagent:/jolokia-jvm-agent.jar\"" >> $CONF_DIR/cassandra-env.sh

# FIXME create README for these args
echo "Starting Cassandra on $POD_IP"
echo CASSANDRA_RPC_ADDRESS ${CASSANDRA_RPC_ADDRESS}
echo CASSANDRA_NUM_TOKENS ${CASSANDRA_NUM_TOKENS}
echo CASSANDRA_CLUSTER_NAME ${CASSANDRA_CLUSTER_NAME}
echo CASSANDRA_LISTEN_ADDRESS ${POD_IP}
echo CASSANDRA_BROADCAST_ADDRESS ${POD_IP}
echo CASSANDRA_BROADCAST_RPC_ADDRESS ${POD_IP}

export CLASSPATH=/kubernetes-cassandra.jar

# create telegraf user
curl -XPOST "http://influxdb.kube-system.svc:8086/query?u=root&p=root" \
         --data-urlencode "q=CREATE USER ${INFLUXDB_TELEGRAF_USERNAME} WITH PASSWORD '${INFLUXDB_TELEGRAF_PASSWORD}'"
curl -XPOST "http://influxdb.kube-system.svc:8086/query?u=root&p=root" \
         --data-urlencode "q=GRANT ALL on k8s to ${INFLUXDB_TELEGRAF_USERNAME}"
sed -i "s/superSecurePassword/${INFLUXDB_TELEGRAF_PASSWORD}/" /etc/telegraf/telegraf-node.conf
sed -i "s/username = \"telegraf\"/username = \"${INFLUXDB_TELEGRAF_USERNAME}\"/" /etc/telegraf/telegraf-node.conf

cat $CFG

/usr/bin/telegraf --quiet --config /etc/telegraf/telegraf-node.conf 2>&1 &
cassandra -f -R
