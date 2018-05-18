#!/usr/bin/env bash

# Gloabal Variables
LOGFILE="$HOME/logs/remote-mount.log"
REMOTE="omg-cache:"
MPOINT="$HOME/cloud/orionsbelt-RW"

function _mountpoint() {
  echo "creating $MPOINT"
  mkdir -p "$MPOINT" \
    "$LOGFILE" &>>printf &
}

function _unmount() {
  echo "Unmounting $REMOTE from $MPOINT"
  fusermount -uz "$MPOINT" \
    &>>"$LOGFILE" &
}

function _install() {
  brew install rclone
}

function _mountif() {
  ## CHECK IF MOUNT ALREADY EXIST AND MOUNT IF NOT
  if mountpoint -q "$MPOINT"; then
    echo "$MPOINT already mounted" \
      else
    echo "Mounting $REMOTE to $MPOINT"
    exit
  fi
}

function _normalmount() {
  local rcloneARGS=(
    "--allow-other"
    "--buffer-size=128M"
    "--timeout=5s"
    "-vv"
    "--contimeout=5s")
  rclone mount $REMOTE "$MPOINT" "${rcloneARGS[@]}" \
    &>>"$LOGFILE" &
}

function _cachemount() {
  local rclonecacheARGS=(
    "--cache-tmp-upload-path=$HOME/.cache/rclone/cache-backend"
    "--cache-chunk-path=$HOME/.cache/rclone/cache-backend"
    "--cache-chunk-size=1M"
    "--cache-total-chunk-size=100G"
    "--cache-chunk-clean-interval=1m"
    "--cache-info-age=12h"
    "--cache-read-retries=10"
    "--cache-workers=20"
    "--cache-db-path=$HOME/.cache/rclone/cache-backend"
    "--cache-writes"
    "--cache-tmp-wait-time=10s"
    )
  local rcloneARGS=(
    "--allow-other"
#    "--fuse-flag=sync_read"
    "--buffer-size=256"
    "--attr-timeout=10s"
    "--timeout=5s"
    "--max-read-ahead=1M"
    "--cache-dir=$HOME/.cache/rclone"
#    "--vfs-cache-max-age=6h"
    "--dir-cache-time=5m"
#    "--vfs-cache-mode=writes"
    "-vvv"
#    "--vfs-cache-max-age=11h"
#    "--vfs-cache-poll-interval=1m"
    "--poll-interval=40s"
    "--contimeout=5s"
    "--stats=10s"
  )
  rclone mount $REMOTE "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$1" \
    &>>"$LOGFILE" &
}

function _purge() {
  if mountpoint -q "$MPOINT"; then
    echo "Purging cache"
    killall -SIGHUP rclone \
      &>>"$LOGFILE" &
  else
    echo "Purging cache"
    _cachemount "--cache-db-purge"
    sleep 10
    _unmount
  fi
}

function _mountbundle() {
  _mountpoint
  _mountif
  _normalmount
}

function _mountcachebundle() {
  _mountpoint
  _mountif
  _cachemount "-vv"
}

function _hlp() {
  $ECHO ""
  $ECHO "Usage: rclone_mount.sh <option(s)>"
  $ECHO ""
  $ECHO "Available options:"
  $ECHO "-m, --mount    : Mount your rclone remote"
  $ECHO "-h, --help     : This help page."
  $ECHO "-p, --purge    : Will purge your rclone cache and mount."
  $ECHO "-i, --install	: Installs rclone via linuxbrew"
  $ECHO "-c, --cache    : Mount rclone remote with cacheing parameters"
  $ECHO ""
}

while [ ! $# -eq 0 ]; do
  case $1 in
  -h | --help)
    _hlp
    exit 0
    ;;
  -p | --purge)
    _purge
    exit 0
    ;;
  -m | --mount)
    _mountbundle
    exit 0
    ;;
  -u | --unmount)
    _unmount
    exit 0
    ;;
  -c | --cache)
    _mountcachebundle
    exit 0
    ;;
  -i | --install)
    _install
    exit 0
    ;;
  *)
    _hlp
    exit 0
    ;;
  esac
  shift
done
