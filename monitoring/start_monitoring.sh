#!/bin/bash

DATE=$(date +%F)
DIR=$(dirname $0)

mkdir -p $DIR/$DATE

date '+%F %T' > $DIR/$DATE/start

vmstat -S K -n 1 36000 > $DIR/$DATE/vmstat &
$DIR/monitor_dbconnections.sh > $DIR/$DATE/db_connections &
$DIR/jboss_requests.sh > $DIR/$DATE/jboss_requests &
$DIR/jboss_stats.sh > $DIR/$DATE/jboss_stats &
$DIR/cycle_threads.sh &

