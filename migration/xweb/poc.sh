#!/bin/bash
#constants
ZONE_PATH=./customer_pz
BACKUP_FILE=$HOME/customer_pz_$(date '+%Y%m%d%H%M%S').tar.gz
DO_BACKUP=0
SERIALDATE=$(date '+%Y%m%d'"01");
VERBOSE=0
EXCLUDE=0
EXCLUDE_FILE='';
MAP_FILE='';
BAIL=0;
DNS_FILE_EXT=.dns

usage() {
 echo "-------------------------------------"
 echo `basename $0`;
 echo "-h :: display this help"
 echo "-b <file> - path to backup file"
 echo "-d <string> - serial date / num field for update"
 echo "-m <file> - ip mapping file"
 echo "-v - enable verbose mode"
 echo "-x <file> - path to exclusion file"
 echo "-z <path> - path to zone files"
}
if [ -z $1 ]; then usage; exit 0; fi;

# handle parameters/ops
while getopts "m:z:b:x:d:vh" opt; do
 case $opt in
 h) usage; exit 0 ;;
 b) BACKUP_FILE=$OPTARG; DO_BACKUP=1 ;;
 d) SERIALDATE=$OPTARG ;;
 m) MAP_FILE=$OPTARG ;;
 x) EXCLUDE=1; EXCLUDE_FILE=$OPTARG ;;
 z) ZONE_PATH=$OPTARG ;;
 v) VERBOSE=1 ;;
 \?) echo "invalid option triggered" >&2 ;;
 esac
done

# sanity checks
if [ ! -f $MAP_FILE ]; then echo "invalid ip mapping file: $MAP_FILE "; BAIL=1; fi;
if [ ! -d $ZONE_PATH ]; then echo "invalid dns zone directory not found: $ZONE_PATH "; BAIL=1; fi;
if [ $EXCLUDE -gt 0 ]; then
 if [ ! -f $EXCLUDE_PATH ]; then echo "invalid dns domain exclusion list file: $EXCLUDE_PATH "; BAIL=1; fi;
fi
# crit bail
if [ $BAIL -gt 0 ]; then exit 1; fi;

# reading in ip mapping
readarray maps < $MAP_FILE
map_count="${#maps[@]}";
map_i=1;
echo -ne " Building ip mapping list for zone file updates ... \r"
SED_CMD="sed -i"
for i in ${maps[@]}; do
  IFS=',' read -ra DATA <<< ${i[@]};
  SED_CMD=" $SED_CMD -e s/${DATA[0]}/${DATA[1]}/g";
  if [ $VERBOSE ]; then echo -ne " Building ip mapping list for zone file updates ... $map_i / $map_count \r"; fi;
  map_i=$((map_i+1));
done;
SED_CMD=" $SED_CMD -e  \"s/.*serial number/\t\t\t$SERIALDATE ; serial number/g\"";
echo "";

# backup the source dns zone directory/files
DO_BACKUP=0;
if [ $DO_BACKUP ]; then
  echo " Backing up $ZONE_PATH "
  tar -czf $BACKUP_FILE $ZONE_PATH;
  if [ ! $? -eq 0 ]; then echo "error with backup file $BACKUP_FILE...exiting"; exit 1; fi;
fi;

# get the source list of files to update
echo " Building list of zone files to update ... ";
files=($(ls -1 $ZONE_PATH| grep "$DNS_FILE_EXT"));
file_count=${#files[@]};
file_i=1;
for file in ${files[@]}; do
	echo $file >> my.log;
done;

echo " Currently $file_count files will be checked ... ";

# handle dns exclusion file as list of domain names.
if [ $EXCLUDE -gt 0 ]; then
  echo "";
  echo " Exclusion file provided, checking domains for exclusion ";
  readarray -t delete < $EXCLUDE_FILE;
  delete_count=${#delete[@]};
  delete_i=1;
  if [ $VERBOSE ]; then 
    echo " $delete_count exclusions loaded from file ";
    echo " this will take a while ...";
  fi;

  for i in ${!files[@]}; do
    filedomain=`basename ${files[$i]} .dns`;
    filename=${files[$i]};
    if [ $VERBOSE ]; then echo -ne " checking $filedomain for exclusion ... $file_i / $file_count \r"; fi;
    for j in ${!delete[@]}; do
      deldomain=${delete[$j]};
      if [ "$filedomain" = "$deldomain" ]; then
        if [ $VERBOSE ]; then echo "Removing $filedomain from dns updates"; echo ""; fi;
        files=("${files[@]/$filename}");
      fi;
    done;
    file_i=$((file_i+1));
  done;
fi

for file in ${files[@]}; do
	echo $file >> out.log;
done;

# stop for now
exit 0;

file_count=${#files[@]};
file_i=1;
# finally do the updates
for file in ${files[@]}; do
  if [ ! -f $ZONE_PATH/$file ]; then echo "$ZONE_FILE/$file no longer exists, skip for now but you should check this."; continue; fi;
  if [ $VERBOSE ]; then echo "Updating $ZONE_PATH/$file ... $file_i / $file_count "; fi;
  file=$((file_i+1));
  eval "$SED_CMD $ZONE_PATH/$file";
done
