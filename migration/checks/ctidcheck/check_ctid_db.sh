#!/bin/bash

while read -r line
do
	sqlite3 check.2018-07-02-21-44-16.db "SELECT * FROM checks WHERE ctid like \"$line\";" 
done < <(cat ctids_source_list)
