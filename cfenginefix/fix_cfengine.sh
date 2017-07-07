#!/bin/bash
# wont mess things up if cfengine is turned off
cfconf="/var/cfengine/inputs/update.conf"
proxy="http://10.16.99.10:8888"
confpath="http://debian.linux.ops.softcom.biz/update.conf"

if [ ! -f  "$cfconf" ] || [ -s "$cfconf" ]
then
  export http_proxy="$proxy"
  wget -O "$cfconf" "$confpath"
  #if [ $? -ne 0 ]; then exit 1; fi;
  unset http_proxy
fi
