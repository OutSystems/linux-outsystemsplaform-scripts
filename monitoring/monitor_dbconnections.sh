#!/bin/bash

DATE=$(date +%F)
DIR=$(dirname $0)

echo ESTABLISHED TOTAL

for s in $(seq 7200); do
	echo $(date +%H:%M:%S) $(netstat -nt | grep :1521 | grep ESTABLISHED | wc -l) $(netstat -nt  | grep :1521 | wc -l)
	sleep 5
done

