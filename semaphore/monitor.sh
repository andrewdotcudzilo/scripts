#!/bin/bash

# recommend running this is a screen session in case
# of disconnects

db="monitor.db"
sleep=10
max_db_size=1000 #megs=1g

if [ -f $db ]; then $(rm -fr ./"$db"); fi;
if [ ! -f $db ]; then sqlite3 "$db" < monitor.sql; fi;


while(true)
do

  thisIteration=$(date +"%Y-%m-%d %H:%M:%S")
  n=0
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
  sleep "$sleep"
done
