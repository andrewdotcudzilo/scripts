#!/bin/bash

# get pids from sem ids, try to find process
arr=($(/usr/bin/ipcs -s | awk '{print $2}' | sed 's/:.*//'))
#remove indexs that aren't semids
unset arr[0]; unset arr[1]; unset arr[2];

#informative, dump all semids, pids
for i in ${arr[@]}
do
  pid=($(/usr/bin/ipcs -s -i "$i" | awk -v RS="" '{print $36}'))
  echo -e "sem id $i has pid $pid"
done

#loop again, this time checking pid in proc, if not there, remove or just verbose
for i in ${arr[@]}
do
  pid=($(/usr/bin/ipcs -s -i "$i" | awk -v RS="" '{print $36}'))
  if [! -z "$pid"] && ["$pid" -ne "0"]
  then
    if [! -d /proc/"$pid" ]
    then
      echo "sem id $i has pid $pid and but should be removed"
      #/usr/bin/ipcrm -s "$i"
    else
      cmd=$(cat /proc/"$pid"/cmdline)
      echo "sem id $i has pid $pid and proc info is: $cmd"
    fi
  fi
done
