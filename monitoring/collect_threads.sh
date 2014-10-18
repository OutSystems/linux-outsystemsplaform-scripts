#!/bin/bash

if [ ! -f /etc/sysconfig/outsystems ]; then
	echo "OutSystems Platform is not installed on this server. Cancelling."
	exit
fi

source /etc/sysconfig/outsystems

DIR=$(mktemp -d)
chmod 777 $DIR
touch $DIR/errors.log

JBOSS_NAME="JBoss"

PROCESS_PID=$(ps -u jboss 2>>/dev/null | grep java | gawk '{print $1}')

if [ "$PROCESS_PID" == "" ]; then
	echo "Could not find the $APPSERVER_NAME process."
	rm -rf $DIR
	exit
fi

su jboss -c "$JAVA_HOME/bin/jstack $PROCESS_PID" > $DIR/threads_JBoss.log 2>> $DIR/errors.log

mkdir -p /root/monitoring/$(date +%F)/threads/

# feel free to add more as required
cp $DIR/threads_JBoss.log /root/monitoring/$(date +%F)/threads/$(date +%F_%H%M%S).log

rm -rf $DIR
