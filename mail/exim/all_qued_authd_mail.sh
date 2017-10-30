#!/bin/bash

while read -r line1
do
  frun=1
  gotres=0
  while read -r line2
  do
    res='';
    res=$(exim -Mvh "$line2" | grep -o "Authenticated-user:.*" | sed -n -e 's/.*Authenticated\-user\:\_//p' | sed 's/.$//')
    if [[ ! -z $res ]]
    then
      if [[ $frun == 1 ]]
      then
        echo "Address: $line1"
        frun=0
      fi
      echo "$res"
      gotres=1
    fi
  done < <(exim -bp | grep "$line1" | awk '{print $3}' | sed '/^$/d') | sort | uniq -c | sort -n
  if [[ $frun == 0 ]] && [[ $gotres > 0 ]]
  then
    echo " --- "
    echo " "
  fi
done < <(
 exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c | sort -n | awk '{if($1==$1+0 && $1>4)print $2}' | \
 sed 's/^.\(.*\).$/\1/' | sed '/^$/d'
)
