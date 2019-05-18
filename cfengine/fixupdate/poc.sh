#!/bin/bash
set -x

#remove known hosts
rm -fr ~/.ssh/known_hosts
while read -r line
do
	./remote.ex "$1" "$line" "$2" & 
done < <(cat source_ip_list.vzlin)
