#!/usr/bin/env bash

################################################################################
############## Rclone mounting script with other features and stuff. ###########
################################################################################
#                   ___           ___           ___                            #
#                  /  /\         /__/\         /  /\                           #
#                 /  /::\       |  |::\       /  /:/_                          #
#                /  /:/\:\      |  |:|:\     /  /:/ /\                         #
#               /  /:/  \:\   __|__|:|\:\   /  /:/_/::\                        #
#              /__/:/ \__\:\ /__/::::| \:\ /__/:/__\/\:\                       #
#              \  \:\ /  /:/ \  \:\~~\__\/ \  \:\ /~~/:/                       #
#               \  \:\  /:/   \  \:\        \  \:\  /:/                        #
#                \  \:\/:/     \  \:\        \  \:\/:/                         #
#                 \  \::/       \  \:\        \  \::/                          #
#                  \__\/         \__\/         \__\/                           #
#                                                                              #
################################################################################
#### rclone credit        : https://github.com/ncw/rclone
###  Install rclone       : https://rclone.org/install/
###  Install rclone       : "brew install rclone"

_Main() {
  # Global Vars:
  # Path to rclone. In most cases, it will be in your $PATH so you shouldnt need to change this.
  RCLONE="rclone"
  # Do not change this option. I use the advanced backend options for mounting.
  REMOTE=":drive:"
  # Your Teamdrive ID. This can be found in the url at the root of your Teamdrive.
  TD='0ANizVBO00Ao1Uk9PVA'
  # Full path to the service account token for authentication of the Teamdrive.
  SA="/home6/omg/.config/rclone/tokens/Owncloud-fb9ead49f333.json"
  # Path to your mount folder.
  MPOINT="$HOME/cloud/rom/"
#  LOGFILE="$HOME/logs/rclone-rom.log"
#  OPERATIONLOG="$HOME/logs/RcloneMountOperations.log"

  ##############################################################################
  # Functions:
  _Setup() {
    _MountCheck() { ## CHECK IF MOUNT ALREADY EXIST AND MOUNT IF NOT
      if mountpoint -q "$MPOINT"; then
        echo "$MPOINT already mounted" | tee -a "$OPERATIONLOG"
      else
        echo "Mounting $MPOINT" | tee -a "$OPERATIONLOG"
      fi
    }

 #   _LogFolder() { # Create log folder location if necessary.
 #     if [ ! -d "$HOME/logs" ]; then
 #       echo "Creating Mount Location" | tee -a "$OPERATIONLOG"
 #       mkdir -p "$HOME/logs"
 #     fi
 #   }

    _MountPoint() { # Create mount location if necessary.
      echo "Creating Mount Location" | tee -a "$OPERATIONLOG"
      if [ ! -d "$MPOINT" ]; then
        mkdir -p "$MPOINT"
      fi
    }

#    _TmpCache() { # Create temporary cache location if necessary.
#      if [ ! -d "$TMPCACHE" ]; then
#        echo "Creating Mount Location" | tee -a "$OPERATIONLOG"
#        mkdir -p "$TMPCACHE"
#      fi
#    }
    _MountCheck && _MountPoint && #_LogFolder && _TmpCache
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
    # Calculate best chunksize for transfer speed.
    AvailableRam=$(free --giga -w | grep Mem | awk '{print $8}')
    case "$AvailableRam" in
    [1-9][0-9] | [1-9][0-9][0-9]) driveChunkSize="1G" ;;
    [6-9]) driveChunkSize="512M" ;;
    5) driveChunkSize="256M" ;;
    4) driveChunkSize="128M" ;;
    3) driveChunkSize="64M" ;;
    2) driveChunkSize="32M" ;;
    [0-1]) driveChunkSize="8M" ;;
    esac

    local TMPCACHE="$HOME/.config/rclone/tmp_upload_cache"
    local rcloneARGS=(
      "--allow-other"
#      "--allow-root"
#      "--contimeout=5s"
#      "--daemon"
      "--drive-chunk-size=$driveChunkSize"
#      "--log-file=$LOGFILE"
#      "--log-level=INFO"
      # "--max-read-ahead=1M"
#      "--rc"
#      "--read-only"
#      "--size-only"
#      "--stats=10s"
      "--tpslimit=10"
      "--tpslimit-burst=10"
#      "--umask=777"
#      "--fuse-flag=sync_read"
#      "--timeout=5s"
      "-P"
      "-vv"
    )

    _purge() { # Purge Rclone Cache while mounted or unmounted.
      if mountpoint -q "$MPOINT"; then
        echo "Purging cache" | tee -a "$OPERATIONLOG"
        killall -SIGHUP rclone
      else
        echo "Purging cache" | tee -a "$OPERATIONLOG"
        _RcloneCacheMount --cache-db-purge
        sleep 10
        _unmount
        sleep 5
        echo "Purge Successful"
        _PlexGuideRcache --cache-db-purge
        sleep 10
        _unmount
        sleep 5
        echo "Purge Successful"

      fi
    }

    _RcloneCacheMount() { # Expects to used with the "Cache" remote.
      local rclonecacheARGS=(
#        "--attr-timeout=1s"
        "--buffer-size=0M"
        "--cache-chunk-clean-interval=15m"
#        "--cache-chunk-path=$HOME/.cache/rclone/zendrive/cache-backend"
        '--cache-chunk-size=5M'
#        "--cache-db-path=$HOME/.cache/rclone/zendrive/cache-backend"
        "--cache-db-purge"
#        "--cache-dir=$HOME/.cache/rclone/zendrive"
#        "--cache-info-age=168m"
        "--cache-read-retries=10"
        "--cache-tmp-upload-path=$TMPCACHE"
        "--cache-tmp-wait-time=15m"
        '--cache-chunk-total-size=100G'
        '--cache-workers=8'
        "--cache-writes"
        '--dir-cache-time=15m'
        '--drive-scope=drive'
        "--drive-service-account-file=$SA"
        "--drive-team-drive=$TD"
#        "--poll-interval=40s"
#        "--vfs-cache-max-age=675h"
        "--vfs-cache-mode=writes"
#        "--vfs-read-chunk-size-limit=1G"
#        "--vfs-read-chunk-size=32M"
        #    "--vfs-cache-max-age=11h"
        #    "--vfs-cache-mode=writes"
        #    "--vfs-cache-poll-interval=1m"
        "--write-back-cache"
      )
      "$RCLONE" mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$@" &&
        echo "Mount Successful" || echo "Mount Failed"
    }
 
    _NormalMount() { # Mount Rclone without any caching.
      "$RCLONE" mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}" &&
        echo "Mount Successful" || echo "Mount Failed" &
    }

    while [ ! $# -eq 0 ]; do
      case $1 in
      --cache)
        _Setup
        _RcloneCacheMount
        ;;
      --mount)
        _Setup
        _NormalMount
        ;;
      --CachePurge)
        _purge
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
    $ECHO ""
  }

  while [ ! $# -eq 0 ]; do
    case $1 in
    -p | --purge)
      _RcloneMount --CachePurge
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
    -i | --install)
      _install
      exit 0
      ;;
    -h | --help | *)
      _hlp
      exit 0
      ;;
    esac
    shift
  done
}
_Main "$@"
