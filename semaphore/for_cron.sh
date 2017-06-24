#!/bin/bash
logfile='/var/local/semaphore-cleanup.log';
ipcs_cmd=$(which ipcs);
ipcrm_cmd=$(which ipcrm);
arr=($(/usr/bin/ipcs -s | awk '{print $2}' | sed 's/:.*//'))
unset arr[0]; unset arr[1]; unset arr[2]; #depending on headers, etc, not semaphores

for i in ${arr[@]}; do
  pid=($("$ipcs_cmd" -s -i "$i" | awk -v RS="" '{print $36}'));
  if [ "$pid" ] && [ "$pid" -ne "0" ] && [ ! -d /proc/"$pid" ]; then
    $("$ipcrm_cmd") -s "$i"
    # log it if we wnat I suppose
    echo -e "$(date) - Removed semaphore with sem id $i due to terminated pid $pid" >> "$logfile"
  else
    $("$ipcrm_cmd") -s "$i" #no pid associated with semaphore, kill it.
    echo -e "$(date) - Removed semaphore with sem id $i due to no associated pid found" >> "$logfile"
  fi
done
