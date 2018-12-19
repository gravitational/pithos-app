#!/usr/bin/env bash
# -*- mode: sh; -*-

# File: start-telegraf.sh
# Time-stamp: <2018-12-10 17:16:10>
# Copyright (C) 2018 Gravitational Inc
# Description:

# set -o xtrace
set -o nounset
set -o errexit
set -o pipefail

# create telegraf user
curl -XPOST "http://influxdb.monitoring.svc:8086/query?u=root&p=root" \
         --data-urlencode "q=CREATE USER ${INFLUXDB_TELEGRAF_USERNAME} WITH PASSWORD '${INFLUXDB_TELEGRAF_PASSWORD}'"
curl -XPOST "http://influxdb.monitoring.svc:8086/query?u=root&p=root" \
         --data-urlencode "q=GRANT ALL on k8s to ${INFLUXDB_TELEGRAF_USERNAME}"

# start telegraf
/usr/bin/telegraf --config /etc/telegraf/telegraf.conf
