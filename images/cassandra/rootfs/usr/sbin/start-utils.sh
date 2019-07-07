#!/bin/bash

if [ "x$CRON_SCHEDULE" = "x" ]; then
    CRON_SCHEDULE='0 0 * * *'
fi

echo "$CRON_SCHEDULE "'root sleep $((RANDOM%30))m && nodetool -p 7199 -h localhost repair >> /var/log/cron.log 2>&1' > /etc/cron.d/cassandra

# watch /var/log/cron.log restarting if necessary
cron && tail -f /var/log/cron.log
