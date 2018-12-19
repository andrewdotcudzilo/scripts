#!/bin/bash

#set -x
ZONE_PATH=./customer_pz
BACKUP_FILE=$HOME/customer_pz_$(date '+%Y%m%d%H%M%S').tar.gz
SERIALDATE=$(date '+%Y%m%d'"01");

#check for mapping file
if [ ! -f $1 ]; then echo "invalid map file"; exit 1; fi;

#check for zone path/dir
if [ ! -d $ZONE_PATH ]; then echo "zone directory not found, exiting..."; exit 1; fi;

#check for exclusions
EXCLUDE=0;
if [ ! -z $2 ]; then
	if [ ! -f $2 ]; then echo "exclude file not found, exiting..."; exit 1; 
	else EXCLUDE=1; 
	fi;
fi;

readarray rows < $1;
MAP_COUNT="${#rows[@]}";
COUNT=1;

SEDSTR="sed -i"
for i in ${rows[@]}; do
	IFS=',' read -ra DATA <<< ${i[@]};
	SEDSTR=" $SEDSTR -e s/${DATA[0]}/${DATA[1]}/g";
	echo -ne "Buiding map file - item $COUNT of $MAP_COUNT ...\r";
	COUNT=$((COUNT+1));
done;
SEDSTR=" $SEDSTR -e \"s/.*serial number/\t\t\t$SERIALDATE ; serial number/g\"";

#back customer_pz
echo "";
echo "Backing up $ZONE_PATH ...";
tar -czf $BACKUP_FILE $ZONE_PATH;
if [ ! $? -eq 0 ]; then echo "error with backup file $BACKUP_FILE...exiting"; exit 1; fi;


# generate working list of files to update
files=($(ls -1 $ZONE_PATH|grep ".dns"));
FILE_COUNT="${#files[@]}";
echo "$FILE_COUNT files to be updated...";

if [ $EXCLUDE -eq 1 ]
then
	echo "checking files to be removed from updates";
	readarray delete < $2;

	for i in ${!files[@]}; do
		echo "checking: "${files[$i]};
		for j in ${!delete[@]}; do
			VAL="${delete[$j]%?}.dns";
			if [ "${files[$i]}" = "$VAL" ]; then echo "match ${files[$i]} $VAL"; files=("${files[@]/$VAL}"); fi;
		done;
	done;
fi

for file in ${files[@]}; do echo "$file" >> out.log; done;

exit 0;
for file in ${files[@]}; do
	if [ ! -f $ZONE_PATH/$file ]; then echo "$file no longer exists, skipping."; continue; fi;
	echo "$ZONE_PATH/$file";
	eval "$SEDSTR $ZONE_PATH/$file";
done;
