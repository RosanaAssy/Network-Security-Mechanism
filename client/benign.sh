#!/bin/bash
# Normal user traffic, running all the time:
#   - opens the web page every 3 seconds
#   - logs in over SSH with the CORRECT password every 30 seconds
# Any alert that involves this client (172.28.0.30) is a false alarm.

VICTIM=172.28.0.10
i=0
while true; do
  curl -s -o /dev/null -w "web %{http_code}\n" "http://$VICTIM/"
  if (( i % 10 == 0 )); then
    sshpass -p sunshine ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      student@"$VICTIM" uptime && echo "ssh ok"
  fi
  i=$((i + 1))
  sleep 3
done
