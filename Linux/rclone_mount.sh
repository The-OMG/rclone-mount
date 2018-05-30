#!/usr/bin/env bash

_Main() {
  # Global Vars:
  REMOTE="OMG_share-cacheBACSYNC:"
  MPOINT="$HOME/cloud/$REMOTE"
  LOGFILE="$HOME/logs/RcloneMount-$REMOTE.log"
  OPERATIONLOG="$HOME/logs/RcloneMountOperations-$REMOTE.log"

  ##############################################################################
  # Functions:
  _Setup() {
    _MountCheck() { ## CHECK IF MOUNT ALREADY EXIST AND MOUNT IF NOT
      if mountpoint -q "$MPOINT"; then
        echo "$MPOINT already mounted" | tee -a "$OPERATIONLOG"
      else
        echo "Mounting $MPOINT" | tee -a "$OPERATIONLOG"
        exit
      fi
    }

    _LogFolder() { # Create log folder location if necessary.
      if [ ! -d "$HOME/logs" ]; then
        echo "Creating Mount Location" | tee -a "$OPERATIONLOG"
        mkdir -p "$HOME/logs"
      fi
    }

    _MountPoint() { # Create mount location if necessary.
      echo "Creating Mount Location" | tee -a "$OPERATIONLOG"
      if [ ! -d "$MPOINT" ]; then
        mkdir -p "$MPOINT"
      fi
    }

    _TmpCache() { # Create temporary cache location if necessary.
      if [ ! -d "$TMPCACHE" ]; then
        echo "Creating Mount Location" | tee -a "$OPERATIONLOG"
        mkdir -p "$TMPCACHE"
      fi
    }
    _MountCheck
    _LogFolder
    _MountPoint
    _TmpCache
  }

  _purge() { # Purge Rclone Cache while mounted or unmounted.
    if mountpoint -q "$MPOINT"; then
      echo "Purging cache" | tee -a "$OPERATIONLOG"
      killall -SIGHUP rclone
    else
      echo "Purging cache" | tee -a "$OPERATIONLOG"
      _RcloneMount --CachePurge
      sleep 10
      _unmount
    fi
  }

  _unmount() { # Unmount a mounted remote.
    echo "Unmounting $REMOTE from $MPOINT" | tee -a "$OPERATIONLOG"
    fusermount -uz "$MPOINT" | tee -a "$LOGFILE"
  }

  _install() { # Installs the latest rclone via linuxbrew.
    brew install rclone | tee -a "$OPERATIONLOG"
  }
  ##############################################################################
  _RcloneMount() {
    local rcloneARGS=(
      "--allow-other"
      "--contimeout=5s"
      "--log-file=$LOGFILE"
      "--log-level=DEBUG"
      # "--max-read-ahead=1M"
      # "--rc"
      # "--size-only"
      "--stats=10s"
      "--timeout=5s"
      #    "--fuse-flag=sync_read"
    )

    _RcloneCacheMount() { # Expects to used with the "Cache" remote.
      local TMPCACHE="$HOME/.config/plex/rclone_cache"
      local rclonecacheARGS=(
        "--attr-timeout=10s"
        "--buffer-size=64M"
        "--cache-chunk-clean-interval=1m"
        "--cache-chunk-path=$HOME/.cache/rclone/cache-backend"
        "--cache-chunk-size=10M"
        "--cache-db-path=$HOME/.cache/rclone/cache-backend"
        "--cache-dir=$HOME/.cache/rclone"
        "--cache-info-age=10m"
        "--cache-read-retries=10"
        "--cache-tmp-upload-path=$TMPCACHE"
        "--cache-tmp-wait-time=10s"
        "--cache-total-chunk-size=100G"
        "--cache-workers=8"
        "--cache-writes"
        "--dir-cache-time=4m"
        "--poll-interval=40s"
        "--vfs-cache-max-age 675h"
        "--vfs-read-chunk-size-limit=1G"
        "--vfs-read-chunk-size=32M"
        #    "--vfs-cache-max-age=11h"
        #    "--vfs-cache-mode=writes"
        #    "--vfs-cache-poll-interval=1m"
      )
      rclone mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$@" &
    }
    _PlexGuideRcache() {
      local rclonecacheARGS=(
        "--attr-timeout=1s"
        "--buffer-size 0M"
        "--cache-chunk-size=10M"
        "--cache-db-path=$HOME/.cache/rclone/.rcache"
        "--cache-info-age=10m"
        "--cache-workers=8"
        "--cache-writes"
        "--dir-cache-time=4m"
        "--umask 002"
      )
      rclone mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$@" &
    }

    _NormalMount() { # Mount Rclone without any caching.
      rclone mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}" &
    }

    while [ ! $# -eq 0 ]; do
      case $1 in
      --cache)
        _RcloneCacheMount
        exit 0
        ;;
      --rcache)
        _PlexGuideRcache
        exit 0
        ;;
      --mount)
        _NormalMount
        exit 0
        ;;
      --CachePurge)
        _RcloneCacheMount --cache-db-purge
        _PlexGuideRcache --cache-db-purge
        exit 0
        ;;
      esac
      shift
    done
  }

  ##############################################################################

  _hlp() {
    $ECHO ""
    $ECHO "Usage: rclone_mount.sh <option(s)>"
    $ECHO ""
    $ECHO "Available options:"
    $ECHO "-c, --cache    : Mount rclone remote with cacheing parameters"
    $ECHO "-h, --help     : This help page."
    $ECHO "-i, --install	: Installs rclone via linuxbrew"
    $ECHO "-m, --mount    : Mount your rclone remote"
    $ECHO "-p, --purge    : Will purge your rclone cache and mount."
    $ECHO "-r, --rcache    : Mount rclone remote with PlexGuide cacheing parameters"
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
      _RcloneMount --mount
      exit 0
      ;;
    -u | --unmount)
      _unmount
      exit 0
      ;;
    -c | --cache)
      _RcloneMount --cache
      exit 0
      ;;
    -r | --rcache)
      _RcloneMount --rcache
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
}
_Main "$@"
