#!/bin/bash

while read -r line1
do
  frun=1
  while read -r line2
  do
    res='';
    res=$(exim -Mvh "$line2" | grep -o "Authenticated-user:.*" | sed -n -e 's/.*Authenticated\-user\:\_//p' | sed 's/.$//')
    if [[ ! -z $res ]]
    then
      if [[ $fun==1 ]]; then echo "$line1"; fi;
      frun=0
      echo "$res"
      echo "$line2"
    fi
  done < <(exim -bp | grep "$line1" | awk '{print $3}' | sed '/^$/d')
  if [[ $frun==0 ]]; then echo "---"; fi;
done < <(
 exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c | sort -n | awk '{if($1==$1+0 && $1>4)print $2}') | \
 sed 's/^.\(.*\).$/\1/' | sed '/^$/d'
)
