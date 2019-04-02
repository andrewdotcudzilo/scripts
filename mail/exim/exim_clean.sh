#!/bin/bash
### *Ultimate* exim mail cleanup script
### this is destructive, know what it does before you try using it.
FROM_MIN_LIMIT=25
EXIM_PATH=/var/spool/exim4/input/
MAX_LIM_AUTH_SENDER=150

# mail older than 7 days
find /var/spool/exim4/{input,msglog} -type f -mtime +7 -name 1\* | xargs rm -v

# frozen and null sender
exim -bp | grep '<>\|<"' | awk '{print $3}' | xargs -n1 exim -Mrm

### search auth senders; if sender has >$MAX_LIM_AUTH_SENDER emails in que,
# consider it spam and deletes all messages.
while read -r line
do
  if [[ ! -z  $line ]]
  then
    echo "Removing emails from Authenticated User: $line because count > $MAX_LIM_AUTH_SENDER"
    echo "You should probably have already found/submitted abuse cases for these"
    echo "accounts/emails"
    grep -rl "$line" "$EXIM_PATH" |  sed -e 's@.*/@@' | sed -e 's/-[DHJ]$//' |  xargs -n1 exim -Mrm
  fi

done < <(grep -r "Authenticated-user:_.*" "$EXIM_PATH" 2>&1 | awk -F"_" {'print $2'} | \
  awk -F"@" '{print $1 "@" $2}' | sort | uniq -c | sort -n | \
  awk '{if($1==$1+0 && $1>"$MAX_LIMIT_PER_AUTH_SENDER")print $2}' | sed '/^\s*$/d')

### run exipick looking for large amount of messages with specific "From" email address
# if they match our second conditional(s) they are deleted
while read -r line
do
  if [[ ! -z  $line ]]
  then
    #i found some linux hosts arent handling or statements correctly in regex
    DEL=0;

    if [[ $(echo "$line" | grep "\.trade$") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "\.bid$") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "\.returns\.groups\.yahoo\.com$") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "\.win$") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "\.club$") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "support@caex.com") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "softcom.com") ]]
      then DEL=1
    elif [[ $(echo "$line" | grep "softcom.biz") ]]
      then DEL=1

    fi

    if [[ $DEL>0 ]]
    then
      echo "Removing $line emails"
      grep -rl "$line" "$EXIM_PATH" |   sed -e 's@.*/@@' -e 's/-[DHJ]$//' | xargs -n1 exim -Mrm
    fi
  fi
done < <(exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c| sort -n | \
  awk '{if($1==$1+0 && $1>"$FROM_MIN_LIMIT")print $2}' | sed 's/^.\(.*\).$/\1/' | sed '/^\s*$/d' )


while read -r line
do
  grep -rl "$line" "$EXIM_PATH" |  sed -e 's@.*/@@' -e 's/-[DHJ]$//' |  xargs -n1 exim -Mrm
done < <(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_blacklist)


while read -r line
do
  grep -rl @"$line" "$EXIM_PATH" |   sed -e 's@.*/@@' -e 's/-[DHJ]$//' | xargs -n1 exim -Mrm
done < <(/usr/bin/curl http://xsmtpsupport.mail2web.com/blacklists/local_sender_domain_blacklist)



### determined too agressivve
# cannot be trusted at this point in time.
#while read -r line1
#do
#  grep -rl "$line1" "$EXIM_PATH" |  sed -e 's/^\.\///' -e 's/-[DH]$//' | sed 's/.*\///' | xargs -n1 exim -Mrm
#done < <(exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c| sort -n | awk '{if($1==$1+0 && $1>"$MIN_LIMIT")print $2}')

#stop exim
/etc/init.d/exim4 stop; sleep 60; killall exim4; sleep 10; while(killall -9 exim4); do sleep 2; done;
# restart exim
/etc/init.d/exim4 start
