#!/bin/bash

LOG_FILE=$1
OUT_LOG_FILE=$LOG_FILE.`date +"%Y%m%d"`
HTTP_PID=`pstree -p | grep httpd | head -n1 | grep -Po 'httpd\(\d+\)' | tr -d 'httpd()'`

mv $LOG_FILE $OUT_LOG_FILE
kill -s SIGUSR1 $HTTP_PID
