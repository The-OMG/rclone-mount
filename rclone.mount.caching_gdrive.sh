#!/bin/bash
## GLOBAL VARS
LOGFILE="$HOME/logs/remote.mount-read-rclone.log"
REMOTE="remote.mount:"
MPOINT="$HOME/cloud"

mkdir "$MPOINT" \

function _unmount() {
  ## UNMOUNT IF SCRIPT WAS RUN WITH unmount PARAMETER
  if [[ $1 == "unmount" ]]; then
  echo "Unmounting $MPOINT"
  fusermount -uz "$MPOINT"
  exit
  fi
}

function _purge() {
## UNMOUNT IF SCRIPT WAS RUN WITH unmount PARAMETER
if [[ $1 == "purge" ]]; then
  echo "Unmounting $MPOINT"
  fusermount -uz "$MPOINT"
  exit
fi
}

function _mountif() {
  ## CHECK IF MOUNT ALREADY EXIST AND MOUNT IF NOT
  if mountpoint -q "$MPOINT"; then
  echo "$MPOINT already mounted"
  else
    echo "Mounting $MPOINT"
}

function _mount() {
  rclone mount $REMOTE "$MPOINT" \
  --allow-other \
  --read-only \
  --buffer-size 128M \
  --timeout 5s \
  --contimeout 5s \
  -vv &>>"$LOGFILE" &
fi
exit
}

_unmount
_purge
_mountif
_mount