#!/bin/bash

if [ ! -f /etc/sysconfig/outsystems ]; then
        echo "OutSystems Platform is not installed on this server. Cancelling."
        exit
fi

CASEID=$1

source /etc/sysconfig/outsystems

DIR=$(mktemp -d)
chmod 777 $DIR
touch $DIR/errors.log


PROCESS_PID=$(ps -ef | grep java.*standalone-outsystems.xml | grep -v grep | awk '{print $2}')


if [ "$PROCESS_PID" == "" ]; then
        echo "Could not find the $APPSERVER_NAME process."
        rm -rf $DIR
        exit
fi

su wildfly -c "$JAVA_HOME/bin/jstack $PROCESS_PID" > $DIR/threads_JBoss.log 2>> $DIR/errors.log

aws s3 cp $DIR/threads_JBoss.log s3://outsystemssupport/cases/$CASEID/$(hostname)/$(date +%F_%H%M%S).log

rm -rf $DIR
