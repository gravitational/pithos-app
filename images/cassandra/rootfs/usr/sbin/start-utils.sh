#!/bin/bash

if [ "x$CRON_SCHEDULE" = "x" ]; then
    CRON_SCHEDULE='0 0 * * *'
fi

echo "$CRON_SCHEDULE "'root nodetool -p 7199 -h cassandra.default.svc repair -seq && for pod_ip in $(kubectl get pods -l pithos-role=cassandra -o jsonpath="{.items[*].status.podIP}"); do nodetool -p 7199 -h $pod_ip compact; done >> /var/log/cron.log 2>&1' > /etc/cron.d/cassandra

# create telegraf user
curl -XPOST "http://influxdb.kube-system.svc:8086/query?u=root&p=root" \
         --data-urlencode "q=CREATE USER ${INFLUXDB_TELEGRAF_USERNAME} WITH PASSWORD '${INFLUXDB_TELEGRAF_PASSWORD}'"
curl -XPOST "http://influxdb.kube-system.svc:8086/query?u=root&p=root" \
         --data-urlencode "q=GRANT ALL on k8s to ${INFLUXDB_TELEGRAF_USERNAME}"
sed -i "s/superSecurePassword/${INFLUXDB_TELEGRAF_PASSWORD}/" /etc/telegraf/telegraf.conf
sed -i "s/username = \"\${INFLUXDB_TELEGRAF_USERNAME}\"/username = \"${INFLUXDB_TELEGRAF_USERNAME}\"/" /etc/telegraf/telegraf.conf

# start telegraf
/usr/bin/telegraf --quiet --config /etc/telegraf/telegraf-status.conf 2>&1 &

# watch /var/log/cron.log restarting if necessary
cron && tail -f /var/log/cron.log
