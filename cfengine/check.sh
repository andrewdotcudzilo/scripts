#!/bin/bash

DEB_PATH=/var/lib/cfengine/inputs
RH_PATH=/var/cfengine/inputs
PATH=""

if [ -d "$DEB_PATH" ]; then PATH=$DEB_PATH;
elif [ -d "$RH_PATH" ]; then PATH=$RH_PATH;
else exit 1;
fi;

#rm -f "$PATH/update.conf"

if [ ! -f "$PATH/update.conf" ]
then
	echo "$PATH/update.conf not found, getting"
	export http_proxy="http://10.16.99.10"
	/usr/bin/wget -O "$PATH/update.conf" http://debian.linux.ops.softcom.biz/update.conf
	unset http_proxy
fi

CFRUNNING=$(ps aux|grep "/usr/sbin/cfexecd"|grep -v grep|wc -l)
if [ "$CFRUNNING" -eq "0" ]
then
	/usr/bin/killall -9 cfagent
	/etc/init.d/cfexecd start
	/bin/echo "cfexecd appears to be not running, killed existing agents and started"
fi

/etc/init.d/cfexecd restart
/bin/sleep 5
/usr/sbin/cfagent --no-splay



