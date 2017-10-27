#!/bin/bash
### *Ultimate* exim mail cleanup script
### this is destructive, know what it does before you try using it.

function usage() {
  echo "Usage: $0 integer"
  echo " "
  echo "Where 'integer' is a minimum number of email messages stuck in que"
  echo "from a specific address (ie: bingo@trade.bid)"
  echo "If you don't know what to put, 5 is a decent number"
  echo "This script is destructive so don't use it if you don't understand it."
  exit 1
}

[[ $# -eq 0 ]] && usage

MIN_LIMIT=$1

# mail older than 7 days
find /var/spool/exim4/{input,msglog} -type f -mtime +7 -name 1\* | xargs rm -v

# frozen and null sender
exim -bp | grep '<>\|<"' | awk '{print $3}' | xargs -n1 exim -Mrm

# run  exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c | sort -n to get number of
# messages in que per from address, and delete them if from has more than N messages "

EXIM_PATH=/var/spool/exim4/input/
while read -r line1
do
  grep -rl "$line1" "$EXIM_PATH" |  sed -e 's/^\.\///' -e 's/-[DH]$//' | sed 's/.*\///' | xargs -n1 exim -Mrm
done < <( exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c| sort -n | awk '{if($1==$1+0 && $1>"$MIN_LIMIT)print $2}')

# restart exim
/etc/init.d/exim4 stop; sleep 60; killall exim4; sleep 10; while(killall -9 exim4); do sleep 2; done; /etc/init.d/exim4 start
