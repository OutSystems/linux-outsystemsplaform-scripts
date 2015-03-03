#!/bin/bash

source /etc/sysconfig/outsystems

ESPACES=$(ls $JBOSS_HOME/standalone/deployments/ | grep \\.war$ | grep -v customHandlers | sed s/\\.war$// | sort)

rm -f /tmp/deploy_check.tgz /tmp/*.os.md5

for espace in $ESPACES; do
	cd $JBOSS_HOME/standalone/deployments/$espace.war
	find -type f -or -type l | sort | xargs md5sum > /tmp/$espace.os.md5
	echo $espace $(md5sum /tmp/$espace.os.md5 | awk '{print $1}')
done

ls -lhR $OUTSYSTEMS_HOME > /tmp/ls_R

tar -zcf /tmp/deploy_check.tgz /tmp/ls_R /tmp/*.os.md5
