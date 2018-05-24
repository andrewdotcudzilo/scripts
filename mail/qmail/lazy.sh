#!/bin/bash
/usr/local/script/qmqtool -d -f 'MAILER-DAEMON@xmail'
/usr/local/script/qmqtool -d -f 'rechnung@'
/usr/local/script/qmqtool -d -f 'OnlinePay'
/usr/local/script/qmqtool -d -f 'user@mywebsite.myhosting.com'
/usr/local/script/qmqtool -d -f 'bounce'

SENDER_BLACKLIST=$(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_blacklist)
SENDER_BLACKLIST_WC=$(/usr/bin/echo "$SENDER_BLACKLIST" | wc -w)

SENDER_DOMAIN_BLACKLIST=$(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_domains_blacklist)
SENDER_DOMAIN_BLACKLIST_WC=$(/usr/bin/echo "$SENDER_DOMAIN_BLACKLIST" | wc -w);

COUNTER=1

while read -r line
do
  for word in $line; do
    prog "$word" still working ...
  done
done < <(/bin/echo "$SENDER_BLACKLIST")



#while read -r line
#do
#  /usr/local/script/qmqtool -d -f @"$line"
#done < <(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_domains_blacklist) 

#while read -r line
#do
#  /usr/local/script/qmqtool -d -f "$line"
#done < <(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_blacklist)

#while read -r line
#do
#  del=$(/usr/bin/awk '{if($1==$1+0 && $1>100)print $2}')
#  if [ ! -z "$del" ]
#  then
#    /bin/echo "deleting emails matching $del from qmail que"
#    /usr/local/script/qmqtool -d -f "$del"
#  fi
#done < <(/usr/local/script/qmqtool -l | /usr/bin/awk '$2 == "Sender:" {print $3}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -n)

#/etc/init.d/qmail restart



prog() {
    local w=80 p=$1;  shift
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.};
    # print those dots on a fixed-width space plus the percentage etc. 
    printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*"; 
}
# test loop
for x in {1..100} ; do
    prog "$x" still working...
    sleep .1   # do some work here
done ; echo
