#!/bin/bash
/usr/local/script/qmqtool -d -f 'MAILER-DAEMON@xmail'
/usr/local/script/qmqtool -d -f 'user@mywebsite.myhosting.com'
/usr/local/script/qmqtool -d -f 'bounce'

while read -r line
do
  /usr/local/script/qmqtool -d -f @"$line"
done < <(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_domains_blacklist) 

while read -r line
do
  /usr/local/script/qmqtool -d -f "$line"
done < <(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_blacklist)

while read -r line
do
  /usr/local/script/qmqtool -d -f "$line"
done < <(/usr/local/script/qmqtool -l | awk '$2 == "Sender:" {print $3}' | sort | uniq -c | sort -n | grep '\.trade\|\.win\|\.bid\|\.club' | awk '{print $2}')

while read -r line
do
  del=$(/usr/bin/awk '{if($1==$1+0 && $1>100)print $2}')
  if [ ! -z "$del" ]
  then
    /bin/echo "deleting emails matching $del from qmail que"
    /usr/local/script/qmqtool -d -f "$del"
  fi
done < <(/usr/local/script/qmqtool -l | /usr/bin/awk '$2 == "Sender:" {print $3}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -n)

/etc/init.d/qmail restart
