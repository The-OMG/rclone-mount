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

_Main() {
    # Global Vars:
    RCLONE="rclone"                         # Path to rclone. In most cases, it will be in your $PATH so you shouldnt need to change this.
    REMOTE="drive:/Movies"                 
    MPOINT="$HOME/cloud/Movies/"            # Path to your mount folder.
	
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
	
	# Rclone ENV - dont change
	export RCLONE_DRIVE_CHUNK_SIZE="$driveChunkSize"

    _MountPoint() { # Create mount location if necessary.
        if [ ! -d "$MPOINT" ]; then
		echo "Creating Mount Location"
            mkdir -p "$MPOINT"
        fi
		if [ ! -d "$$HOME/.config/rclone/tmp_upload_cache-$TD/" ]; then
            echo "Creating temp cache Location"
            mkdir -p "$$HOME/.config/rclone/tmp_upload_cache-$TD/"
        fi
    }

    _unmount() { # Unmount a mounted remote.
        echo "Unmounting $REMOTE from $MPOINT"
        fusermount -uz "$MPOINT"
    }

    _install() { # Installs the latest rclone via linuxbrew.
        brew install rclone
    }

    rcloneARGS=(
        "--allow-other"
        "--tpslimit=10"
        "--tpslimit-burst=10"
        "-P"
        "-vvv"
    )

    _RcloneCacheMount() { # Expects to used with the "Cache" remote.
        rclonecacheARGS=(
            "--buffer-size=0M"
			"--cache-remote=$REMOTE"
            "--cache-chunk-clean-interval=15m"
            "--cache-chunk-size=5M"
            "--cache-db-purge=true"
			"--cache-tmp-upload-path=$HOME/.config/rclone/tmp_upload_cache-$TD/"
            "--cache-read-retries=10"
            "--cache-tmp-wait-time=15m"
            "--cache-chunk-total-size=500G"
            "--cache-workers=8"
            "--cache-writes"
            "--dir-cache-time=15m"
            "--drive-scope=drive"
            "--vfs-cache-mode=writes"
            "--write-back-cache"
        )
        until "$RCLONEBINARY" mount ":cache:" "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$@"; do
            _MountPoint
            _unmount
			clear
            echo "rclone mount for $MPOINT crashed with exit code $?.  Respawning.."
            sleep 2
        done
    }

    _NormalMount() { # Mount Rclone without any caching.
        until "$RCLONE" mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}"; do
            _MountPoint
            _unmount
			clear
            echo "rclone mount for $MPOINT crashed with exit code $?.  Respawning.."
            sleep 2
        done
    }

    _purge() { # Purge Rclone Cache while mounted or unmounted.
        if mountpoint -q "$MPOINT"; then
            echo "Purging cache"
            killall -SIGHUP rclone
        else
            echo "Purging cache"
            _RcloneCacheMount --cache-db-purge
            sleep 10
            _unmount
            sleep 5
            echo "Purge Successful"
        fi
    }

    ##############################################################################

    _hlp() {
    ECHO="echo -e"
        $ECHO ""
        $ECHO "Usage: rclone_mount.sh <option(s)>"
        $ECHO ""
        $ECHO "Available options:"
        $ECHO "-c, --cache      : Mount rclone remote with cacheing parameters"
        $ECHO "-h, --help       : This help page."
        $ECHO "-i, --install    : Installs rclone via linuxbrew"
        $ECHO "-m, --mount      : Mount your rclone remote"
        $ECHO "-p, --purge      : Will purge your rclone cache and mount."
        $ECHO ""
    }

    while [ ! $# -eq 0 ]; do
        case $1 in
        -p | --purge)
            _purge
            ;;
        -m | --mount)
            _NormalMount
            ;;
        -u | --unmount)
            _unmount
            ;;
        -c | --cache)
			export RCLONEBINARY="$RCLONE"
            _RcloneCacheMount
            ;;
        -i | --install)
            _install
            ;;
        -h | --help | *)
            _hlp
            ;;
        esac
        shift
    done
}

_Main "$@"
