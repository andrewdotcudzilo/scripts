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


/usr/bin/killall -9 cfagent
/etc/init.d/cfexecd restart
/usr/sbin/cfagent --no-splay



