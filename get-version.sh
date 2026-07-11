#!/bin/bash
export IMG=$(docker build -q --pull --no-cache -t 'get-version' .)

export NETATALK_VERSION=$(docker run --rm -t get-version apk list 2>/dev/null | grep '\[installed\]' | grep "netatalk-[0-9]" | cut -d " " -f1 | sed 's/netatalk-//g' | tr -d '\r')
export ALPINE_VERSION=$(docker run --rm -t get-version cat /etc/alpine-release | tail -n1 | tr -d '\r')
[ -z "$ALPINE_VERSION" ] && exit 1

export IMGTAG=$(echo "$1""a$ALPINE_VERSION-n$NETATALK_VERSION")
# FORCE_REBUILD (set by the workflow for push / manual runs) rebuilds even if
# the versioned image already exists, so code/config changes get republished.
# the nightly schedule leaves it unset and keeps deduping on the version tag.
if [ -n "$FORCE_REBUILD" ]; then
  echo "$IMGTAG"
  exit 0
fi

export IMAGE_EXISTS=$(docker pull "$IMGTAG" 2>/dev/null >/dev/null; echo $?)

# return latest, if container is already available :)
if [ "$IMAGE_EXISTS" -eq 0 ]; then
  echo "$1""latest"
else
  echo "$IMGTAG"
fi