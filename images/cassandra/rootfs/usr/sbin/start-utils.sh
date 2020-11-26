#!/bin/bash

if [ "x$CRON_SCHEDULE" = "x" ]; then
    CRON_SCHEDULE='0 0 * * *'
fi

echo -e "$CRON_SCHEDULE sleep $((RANDOM%30))m && nodetool -p 7199 -h localhost repair" > /tmp/cassandra.cron

supercronic /tmp/cassandra.cron
