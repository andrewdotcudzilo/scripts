#!/usr/bin/env bash

#/usr/local/script/qmqtool -d -f 'MAILER-DAEMON@xmail'
#/usr/local/script/qmqtool -d -f 'rechnung@'
#/usr/local/script/qmqtool -d -f 'OnlinePay'
#/usr/local/script/qmqtool -d -f 'user@mywebsite.myhosting.com'
#/usr/local/script/qmqtool -d -f 'bounce'

for i in `/usr/local/script/qmqtool -l | awk '$2 == "Sender:" {print $3}' | sort | uniq -c | sort -n`
do
  echo "$i"
done
