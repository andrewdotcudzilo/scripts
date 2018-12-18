#!/bin/bash
for file in $(ls|grep .ips); do
 NAME=$(basename $file .ips);
 sed -i "s/^/$NAME,/" $file;
done
