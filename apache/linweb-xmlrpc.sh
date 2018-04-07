#!/bin/bash

PATH=/usr/local/pem/vhosts
LOGFILE=log/access_log
LOGFILE2=log/access_log.processed
LOGFILE3=log/ssl_access_log
LOGFILE4=log/ssl_access_log.processed

while read -r line
do
        /bin/echo "$line"
        /bin/cat "$line"/"$LOGFILE" "$line"/"$LOGFILE2" "$line"/"$LOGFILE3" "$line"/"$LOGFILE4" | /bin/grep xmlrpc | /bin/awk '{print $1}' | /bin/sort -n | /usr/bin/uniq -c | /bin/sort -nr
        #/bin/cat "$line"/"$LOGFILE"| /usr/bin/wc -l
        echo "-------------------------------------------"
done < <(/usr/bin/find "$PATH" -type d -maxdepth 1)
