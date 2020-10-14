#!/bin/bash
[[ $(ps aux | grep '[n]etatalk -d\|[a]vahi-daemon\|[d]bus-daemon\|[r]unsvdir' | wc -l) -ge '4' ]]
exit $?
