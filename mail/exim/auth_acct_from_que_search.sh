#!/bin/bash
function usage() {
  echo "Usage: $0 search-string"
  exit 1
}

[[ $# -eq 0 ]] && usage

BASE_OUT='';


while read -r line
do
  BASE_OUT=$(exim -Mvh "$line" | grep -o "Authenticated-user:.*" | sed -n -e 's/.*Authenticated\-user\:\_//p' | sed -e 's/\@[^\@]*$//')
done < <(exim -bp | grep "$VARSTRING" | awk '{print $3}')

echo "$BASE_OUT";
