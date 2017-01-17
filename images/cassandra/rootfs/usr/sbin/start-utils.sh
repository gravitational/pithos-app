#!/bin/bash

if [ "x$CRON_SCHEDULE" = "x" ]; then
    CRON_SCHEDULE='0 0 * * *'
fi

echo "$CRON_SCHEDULE "'root nodetool -p 7199 -h cassandra.default.svc repair -seq && for pod_ip in $(kubectl get pods -l pithos-role=cassandra -o jsonpath="{.items[*].status.podIP}"); do nodetool -p 7199 -h $pod_ip compact; done >> /var/log/cron.log 2>&1' > /etc/cron.d/cassandra

# start telegraf
/usr/bin/telegraf --quiet --config /etc/telegraf/telegraf-status.conf 2>&1 &

# watch /var/log/cron.log restarting if necessary
cron && tail -f /var/log/cron.log