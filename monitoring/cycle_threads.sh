#!/bin/bash

for x in $(seq 1200); do 
	/root/monitoring/collect_threads.sh
	sleep 30
done
