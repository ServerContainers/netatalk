#!/bin/bash
[[ $(ps aux | grep '[n]etatalk -d\|[a]vahi-daemon\|[r]unsvdir' | wc -l) -ge '3' ]]
exit $?
