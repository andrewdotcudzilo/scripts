#!/bin/bash
set -x

#remove known hosts
rm -fr ~/.ssh/known_hosts
while read -r line
do
	./remote.ex "$1" "$line" "$2" >>output.log
done < <(cat source_ip_list)
