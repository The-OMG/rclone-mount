#!/bin/bash
## GLOBAL VARS
LOGFILE="$HOME/logs/remote.mount-read-rclone.log"
REMOTE="remote.mount:"
MPOINT="$HOME/cloud"

mkdir "$MPOINT" \

## UNMOUNT IF SCRIPT WAS RUN WITH unmount PARAMETER
if [[ $1 == "unmount" ]]; then
  echo "Unmounting $MPOINT"
  fusermount -uz "$MPOINT"
  exit
fi

## CHECK IF MOUNT ALREADY EXIST AND MOUNT IF NOT
if mountpoint -q "$MPOINT"; then
  echo "$MPOINT already mounted"
else
  echo "Mounting $MPOINT"

## Adjust chunk-check/load threads to match maximum concurrent streams
## Do not use losd-ahead bigger then 10.
## Keep in mind that 1080p stream will need 20Mbit while some scenes can spike to 50/60Mbit.
rclone mount $REMOTE "$MPOINT" \
  --allow-other \
  --read-only \
  --buffer-size 128M \
  --timeout 5s \
  --contimeout 5s \
  -vv &>>"$LOGFILE" &
fi
exit
/
