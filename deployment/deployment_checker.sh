#!/bin/bash

source /etc/sysconfig/outsystems

FRONTENDS=vmes80jboss7centos

ESPACES=$(ls $OUTSYSTEMS_HOME/share | grep \\.war$ | grep -v customHandlers | sed s/\\.war$//)

for espace in $ESPACES; do
	if [ ! -f $OUTSYSTEMS_HOME/share/$espace/full/jsp/_ping.html ]; then
		echo $espace cant check
		continue
	fi
	PING_MD5=$(md5sum $OUTSYSTEMS_HOME/share/$espace/full/jsp/_ping.html | awk '{print $1}' )
	for fe in $FRONTENDS; do
		MD5_FE=$(curl -f -s http://$fe/$espace/_ping.html | md5sum | awk '{print $1}' )
		if [ $MD5_FE != $PING_MD5 ] ; then
			echo error in $espace at $fe
		fi
	done
done
