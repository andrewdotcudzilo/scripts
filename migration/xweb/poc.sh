#!/bin/bash
#set -x
ZONE_PATH=./customer_pz
BACKUP_FILE=$HOME/customer_pz_$(date).tar.gz
SERIALDATE=2018123101

if [ ! -f $1 ]; then echo "invalid map file"; exit 1; fi;

readarray rows < $1
row_array=(${row})

SEDSTR="sed -i"
for i in ${rows[@]}; do
	IFS=',' read -ra DATA <<< ${i[@]};
	SEDSTR=" $SEDSTR -e s/${DATA[0]}/${DATA[1]}/g";
done;
SEDSTR=" $SEDSTR -e \"s/.*serial number/\t\t\t$SERIALDATE ; serial number/g\"";

tar -zcvf $ZONEPATH $BACKUP_FILE;
if [ ! $? -eq 0 ]; then echo "error with backup file $BACKUP_FILE...exiting"; exit 1; fi;

for filename in $ZONE_PATH/*.dns; do
	if [ ! -f $filename ] echo "$filename no longer exists, skipping."; continue; fi;
	echo "$filename"
	eval "$SEDSTR $filename"
done;
