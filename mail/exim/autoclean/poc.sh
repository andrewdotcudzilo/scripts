#!/bin/bash
#set -x
rm -fr ~/.ssh/known_hosts
while read -r line
do
	
	./remote.ex "$1" "$line" "$2" & 
done < <(cat source_ip_list)
wait
echo "All done"
