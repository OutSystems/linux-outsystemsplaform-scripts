#!/bin/bash
# Change Log:
# v1.0 - initial version

# register this in crontab example (1:15 AM everyday):
# 15 1 * * * /opt/outsystems/platform/clean_pta.sh >> /opt/outsystems/platform/logs/pta_clean.log

echo "Clean PTA started at $(date +'%F %H:%M:%S')"

DAYS=5

if [ ! -z $1 ]; then
	DAYS=$1
fi

source /etc/sysconfig/outsystems

service jboss-outsystems stop

if [ -d $JBOSS_HOME/server/outsystems/ ]; then
	pushd $JBOSS_HOME/server/outsystems/deploy/ > /dev/null
else
	pushd $JBOSS_HOME/standalone/deployments/ > /dev/null
fi

for f in $(find -type l -mtime +$DAYS -name '*.war') ; do
  # if is a PTA
  if [[ $(readlink $f) == $OUTSYSTEMS_HOME/test/* ]]; then
	echo Deleting $f $(readlink $f)
	rm -rf $(readlink $f)
	rm -f $f
  fi
done

# not really needed
popd > /dev/null

service jboss-outsystems start

echo "Clean PTA ended at $(date +'%F %H:%M:%S')"