#!/bin/bash

# this will take search-string (ie dong@enlarge.com) and correlate it to what
# authtenticated accounts are sending out mail to address; giving us an idea
# of what accounts need to be further investigated for abuse/password issues

#use with > exipick -b | awk ' $2 == "From:" {print $3}' | sort | uniq -c | sort -n
#to get example domains to search


function usage() {
  echo "Usage: $0 search-string"
  exit 1
}

[[ $# -eq 0 ]] && usage

while read -r line
do
  exim -Mvh "$line" | grep -o "Authenticated-user:.*" | sed -n -e 's/.*Authenticated\-user\:\_//p' | sed 's/.$//'
done < <(exim -bp | grep "$1" | awk '{print $3}' | sed '/^$/d') | sort | uniq -c | sort -n
