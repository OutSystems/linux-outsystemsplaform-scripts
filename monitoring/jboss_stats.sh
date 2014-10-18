#!/bin/bash

source /etc/sysconfig/outsystems

TWIDDLE=$JBOSS_HOME/bin/twiddle.sh

for x in $(seq 7200); do
	BUSY=$($TWIDDLE get jboss.web:type=ThreadPool,name=http-0.0.0.0-8080 currentThreadsBusy)
	QUEUE=$($TWIDDLE get jboss.system:service=ThreadPool QueueSize)
	echo $(date '+%H:%M:%S') $BUSY $QUEUE
	sleep 5
done
