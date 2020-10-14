#!/bin/bash
[[ $(ps aux | grep '[n]etatalk -d\|[a]vahi-daemon\|[d]bus-daemon' | wc -l) -ge '3' ]]
exit $?
