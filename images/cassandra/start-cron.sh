#!/usr/bin/dumb-init /bin/bash

if [ "x$CRON_SCHEDULE" = "x" ]; then
    CRON_SCHEDULE='0 0 * * *'
fi

echo "$CRON_SCHEDULE "'root for pod_ip in $(kubectl get pods -l pithos-role=cassandra -o jsonpath="{.items[*].status.podIP}"); do nodetool -p 7199 -h $pod_ip repair; nodetool -p 7199 -h $pod_ip compact; done >> /var/log/cron.log 2>&1' > /etc/cron.d/cassandra

# watch /var/log/cron.log restarting if necessary
cron && tail -f /var/log/cron.log
