#!/bin/bash

# recommend running this is a screen session in case
# of disconnects

#constants
db="monitor.db"
sleep=30 #secs
max_db_size=1000 #megs=1g

#some default values for vars
num_sem=0;
last_num_sem=0;

# remove old database, create
if [ -f $db ]; then $(rm -fr ./"$db"); fi;
if [ ! -f $db ]; then sqlite3 "$db" < monitor.sql; fi;
db_size=$(du -m ./"$db" | cut -f 1) #get current db size

#loop while db_size less than max
while [ $db_size -lt $max_db_size ]
do

  #get true number of sems used
  num_sem = $(wc -l /proc/sysvipc/sem); num_sem=$((num_sem-1));
  if [ -z "$num_sem"] || [ $num_sem -eq 0 ]; then continue; fi;  #if sems=0, skip

  #setup var values for this iteration
  n=0
  thisIteration=$(date +"%Y-%m-%d %H:%M:%S")

  #compare last run number of sems to this run's number, if <, thne dump sems to database
  if [ $last_num_sem -lt $num_sem];
  then
    while read -r line
    do
      if [ $n -eq 0 ]; then n=$((n+1)); continue; fi; #skip first line of file

      read semid optime ctime <<< $(echo "$line" | awk '{print $2, $9, $10}')
      if [ -z "$semid" ] || [ $semid -eq 0 ]; then n=$((n+1)); continue; fi; #null or owned by pid=0 stay away

      pid=$(ipcs -s -i "$semid" | awk 'FNR==9 {print $0}' | awk '{print $5}')
      if [ -z "$pid" ] || [ "$pid" -eq "0" ]; then n=$((n+1)); continue; fi; #null or pid=0 stay away

      if [ -d /proc/"$pid" ];
      then
        cmd=$(cat /proc/"$pid"/cmdline)
        in_proc="Y"
      else
        cmd=null
        in_proc="N"
      fi;

      sqlite3 monitor.db "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, datetime) VALUES ($semid, $optime, $ctime, $pid, \"$in_proc\", \"$cmd\", \"$thisIteration\")"
      echo "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, datetime) VALUES ($semid, $optime, $ctime, $pid, $in_proc, $cmd, $thisIteration)"
      n=$((n+1))
    done < /proc/sysvipc/sem
  fi

  last_num_sem=num_sem #assign last run value to current, so next iteration can compare it.
  sleep "$sleep"  #we can sleep for less as we technically or just tracking increases, theres more processing, but less data-capture.
  db_size=$(du -m ./"$db" | cut -f 1)
done
