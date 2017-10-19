#!/bin/bash
### *Ultimate* exim mail cleanup script
### this is destructive, know what it does before you try using it.


# mail older than 7 days
find /var/spool/exim4/{input,msglog} -type f -mtime +7 -name 1\* | xargs rm -v

# frozen and null sender
exim -bp | grep '<>\|<"' | awk '{print $3}'' | xargs -n1 exim -Mrm

# for an account, if it has >THRESHOLD of emails in que; considers it spam and removes it
# this doesn't do abuse cases, so you should do those before
#THRESHOLD=7
EXIM_PATH=/var/spool/exim4/input/
while read -r line1
do
  grep -rl "$line1" "$EXIM_PATH" |  sed -e 's/^\.\///' -e 's/-[DH]$//' | sed 's/.*\///' | xargs -n1 exim -Mrm
done < <( exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c| sort -n | awk '{if($1==$1+0 && $1>5)print $2}')

# restart exim
/etc/init.d/exim4 stop; sleep 60; killall exim4; sleep 10; while(killall -9 exim4); do sleep 2; done; /etc/init.d/exim4 start
