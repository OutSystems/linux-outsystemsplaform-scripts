#!/bin/bash

DIR=$1
CP='cp -p'

cat /proc/cpuinfo > $DIR/cpuinfo 2>> $DIR/errors.log 
cat /proc/meminfo > $DIR/meminfo 2>> $DIR/errors.log
df -h -l > $DIR/partInfo 2>> $DIR/errors.log
chkconfig --list iptables > $DIR/iptables_save
echo >> $DIR/iptables_save
/sbin/iptables-save >> $DIR/iptables_save 2>> $DIR/errors.log
ps -A -O pcpu,user,pmem,vsz > $DIR/ps 2>> $DIR/errors.log
$CP /var/log/messages* $DIR 2>> $DIR/errors.log
cp /etc/hosts $DIR/network 2>> $DIR/errors.log
ifconfig -a >> $DIR/network 2>> $DIR/errors.log
netstat -natp >> $DIR/network 2>> $DIR/errors.log
ls -lR $OUTSYSTEMS_HOME > $DIR/ls_outsystems 2>> $DIR/errors.log
ls -lR $JBOSS_HOME > $DIR/ls_jboss 2>> $DIR/errors.log
su $PROCESS_USER -s /bin/bash -c "ulimit -a" > $DIR/limits 2>> $DIR/errors.log
if [ -f /etc/redhat-release ]; then
	cp /etc/redhat-release $DIR 2>> $DIR/errors.log
fi
if [ -f /etc/system-release ]; then
	cp /etc/system-release $DIR 2>> $DIR/errors.log
fi
rpm -qa > $DIR/rpms


echo "Gathering java info..."
$JAVA_BIN/java -XX:+PrintFlagsFinal -version > $DIR/jvm_options 2> $DIR/javaVersion 
