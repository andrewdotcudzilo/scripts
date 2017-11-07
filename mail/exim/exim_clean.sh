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
EXIM_PATH=/var/spool/exim4/input/

# mail older than 7 days
find /var/spool/exim4/{input,msglog} -type f -mtime +7 -name 1\* | xargs rm -v

# frozen and null sender
exim -bp | grep '<>\|<"' | awk '{print $3}' | xargs -n1 exim -Mrm

# this will remove any email with an authenticated sender of $line, if the count is > 200
# this is a temporary measure
while read -r line
do
  if [[ ! -z  $line ]]
  then
    echo "removing emails from auth user $line because they have >=200 emails in que and is likely spam"
    echo "please follow up with abuse cases"
    grep -rl "$line" "$EXIM_PATH" |  sed -e 's/^\.\///' -e 's/-[DH]$//' | sed 's/.*\///' | xargs -n1 exim -Mrm
  fi
done < <(grep -r "Authenticated-user:_.*" "$EXIM_PATH" | awk -F"_" {'print $2'} | awk -F"@" '{print $1 "@" $2}' | sort | uniq -c | sort -n | awk '{if($1==$1+0 && $1>50)print $2}' | sed 's/^.\(.*\).$/\1/' | sed '/^\s*$/d')



## runs exipick looking for large amounts of qued messages "From" a specific email address
# if they match the second conditional (regex) they are auto deleted
# so far just .trade, .bid domain extensions.
# this needs testing.
while read -r line
do
  if [[ ! -z  $line ]]
  then
    #i found some linux hosts arent handling or statements correctly in regex
    DEL=0;

    if [[ $(echo "$line" | grep "\.trade$") ]]; then DEL=1;
    elif [[ $(echo "$line" | grep "\.bid$") ]]; then DEL=1;
    elif [[ $(echo "$line" | grep "\.returns\.groups\.yahoo\.com$") ]]; then DEL=1;
    elif [[ $(echo "$line" | grep "\.win$") ]]; then DEL=1;
    fi

    if [[ $DEL>0 ]]
    then
      echo "Removing $line emails"
      grep -rl "$line" "$EXIM_PATH" |  sed -e 's/^\.\///' -e 's/-[DH]$//' | sed 's/.*\///' | xargs -n1 exim -Mrm
    fi
  fi
done < <(exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c| sort -n | awk '{if($1==$1+0 && $1>"$MIN_LIMIT")print $2}' | sed 's/^.\(.*\).$/\1/' | sed '/^\s*$/d' )

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
