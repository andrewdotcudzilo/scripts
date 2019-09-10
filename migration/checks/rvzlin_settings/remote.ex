#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null  $name@$server 
#match_max 1000000
#set timeout 5
expect "*?re" { send "yes\r" }
expect "?assword:*" { send "$pass\r" }

expect "$prompt" { send "sudo /sbin/sysctl -w net.ipv4.tcp_rmem=\"4096 87380 4194304\" \r" }
expect "*andrewcu:*" { send "$pass\r" }
expect "$prompt" { send "sudo /sbin/sysctl -w net.ipv4.tcp_wmem=\"4096 87380 4194304\" \r" }
expect "$prompt" { send "sudo sed -i.orig -e 's/^VZ_TOOLS_IOLIMIT=\"10485760\"/#VZ_TOOLS_IOLIMIT=\"10485760\"/g' -e 's/^VZ_TOOLS_BCID=/#VZ_TOOLS_BCID=/g' -e 's/^REMOVEMIGRATED=\"yes\"/REMOVEMIGRATED=\"no\"/g' /etc/vz/vz.conf \r" }

expect "$prompt"
#puts $expect_out(buffer) 
