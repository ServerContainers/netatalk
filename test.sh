#!/bin/sh
# automated smoke test for the netatalk container
# builds the image, starts it standalone and asserts afpd comes up and actually
# answers AFP/DSI on port 548
set -eu

IMAGE=netatalk-test
NAME=netatalk-test-run

FAILED=0
fail() {
  echo "FAIL: $*" >&2
  FAILED=1
}

cleanup() {
  echo ">> cleanup: removing container $NAME"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo ">> building image $IMAGE"
docker build -t "$IMAGE" .

echo ">> (re)starting container $NAME"
docker rm -f "$NAME" >/dev/null 2>&1 || true
# minimal config to bring afpd up: one account + one share it can serve
docker run -d --name "$NAME" \
  -e ACCOUNT_tester=testpass \
  -e NETATALK_VOLUME_CONFIG_testshare='[TestShare]; path=/shares/test; valid users = tester' \
  "$IMAGE"

echo ">> waiting for afpd to start (up to ~60s)"
READY=0
i=0
while [ "$i" -lt 30 ]; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "!! container is not running anymore, dumping logs:" >&2
    docker logs "$NAME" >&2 2>&1 || true
    fail "container exited during startup"
    break
  fi
  if docker exec "$NAME" ps aux 2>/dev/null | grep -q '[a]fpd -d'; then
    READY=1
    break
  fi
  i=$((i + 1))
  sleep 2
done

if [ "$READY" -ne 1 ] && [ "$FAILED" -eq 0 ]; then
  echo "!! afpd did not come up in time, dumping logs:" >&2
  docker logs "$NAME" >&2 2>&1 || true
  fail "timed out waiting for afpd"
fi

# only run the deeper assertions if the container is still up
if docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then

  echo ">> assert: container is running"
  docker ps --format '{{.Names}}' | grep -q "^${NAME}$" \
    && echo "ok - container running" || fail "container not running"

  echo ">> assert: netatalk master process present"
  if docker exec "$NAME" ps aux | grep -q '[n]etatalk -d'; then
    echo "ok - netatalk master running"
  else
    fail "netatalk master process not found"
  fi

  echo ">> assert: afpd process present"
  if docker exec "$NAME" ps aux | grep -q '[a]fpd -d'; then
    echo "ok - afpd running"
  else
    fail "afpd process not found"
  fi

  echo ">> assert: TCP port 548 is open inside the container"
  if docker exec "$NAME" bash -c 'exec 3<>/dev/tcp/127.0.0.1/548' 2>/dev/null; then
    echo "ok - port 548 accepts connections"
  else
    fail "could not open TCP connection to port 548"
  fi

  echo ">> assert: port 548 actually answers AFP/DSI (real afpd, not just an open port)"
  # send a 16-byte DSIGetStatus request (flags=0x00 request, command=0x03) and
  # read the reply header back. a genuine afpd answers with flags=0x01 (reply)
  # + command=0x03 + our requestID 0x0001 -> the reply starts with 0103 0001.
  HEX=$(docker exec "$NAME" bash -c '
    exec 3<>/dev/tcp/127.0.0.1/548 || exit 2
    printf "\x00\x03\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >&3
    timeout 4 dd bs=1 count=16 <&3 2>/dev/null | od -An -tx1 | tr -d " \n"
  ' 2>/dev/null || true)
  case "$HEX" in
    01030001*)
      echo "ok - afpd answered DSIGetStatus (DSI reply header: $HEX)"
      ;;
    *)
      fail "port 548 did not return a valid AFP/DSI reply (got header: '${HEX:-<empty>}')"
      ;;
  esac

fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED"
  exit 1
fi
