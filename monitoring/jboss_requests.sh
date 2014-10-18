#!/bin/bash

source /etc/sysconfig/outsystems

DATE=$(date +%F)

if [ ! -f $JBOSS_HOME/server/outsystems/log/localhost_access_log.$DATE.log ]; then
	exit
fi

D=$(date '+%d/%b/%Y:%H:%M')

for x in $(seq 600)  ; do
	s=$(date +%S)
	# bug on 08 and 09 ...
	if [ $s -eq 08 ]; then
		s=8
	fi
	if [ $s -eq 09 ]; then
		s=9
	fi
	let s_time=60-$s+5 
	sleep $s_time

	echo $(date +%H:%M) $(grep $D $JBOSS_HOME/server/outsystems/log/localhost_access_log.$DATE.log | wc -l)
	D=$(date '+%d/%b/%Y:%H:%M')
done


