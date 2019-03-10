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
    RCLONE="$HOME/bin/rclone"                                   # Path to rclone. In most cases, it will be in your $PATH so you shouldnt need to change this.
    REMOTE=":drive:/TV Shows"                                   # Do not change this option. I use the advanced backend options for mounting.
    TD="0AEFojjZ0gu-9Uk9PVA"                                    # Your Teamdrive ID. This can be found in the url at the root of your Teamdrive.
    SA="$HOME/.config/rclone/tokens/Owncloud-5ef5555144cb.json" # Full path to the service account token for authentication of the Teamdrive.
    MPOINT="$HOME/cloud/TV Shows/"                              # Path to your mount folder.

    ##############################################################################
    # Functions:
    _MountPoint() { # Create mount location if necessary.
        echo "Creating Mount Location"
        if [ ! -d "$MPOINT" ]; then
            mkdir -p "$MPOINT"
        fi
    }

    _unmount() { # Unmount a mounted remote.
        echo "Unmounting $REMOTE from $MPOINT"
        fusermount -uz "$MPOINT"
    }

    _install() { # Installs the latest rclone via linuxbrew.
        brew install rclone
    }
    ##############################################################################

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

    rcloneARGS=(
        "--allow-other"
        "--drive-chunk-size=$driveChunkSize"
        "--tpslimit=10"
        "--tpslimit-burst=10"
        "-P"
        "-vvv"
    )

    _RcloneCacheMount() { # Expects to used with the "Cache" remote.
        rclonecacheARGS=(
            "--buffer-size=0M"
            "--cache-chunk-clean-interval=15m"
            "--cache-chunk-size=5M"
            "--cache-db-purge"
            "--cache-read-retries=10"
            "--cache-tmp-upload-path=$TMPCACHE"
            "--cache-tmp-wait-time=15m"
            "--cache-chunk-total-size=100G"
            "--cache-workers=8"
            "--cache-writes"
            "--dir-cache-time=15m"
            "--drive-scope=drive"
            "--drive-service-account-file=$SA"
            "--drive-team-drive=$TD"
            "--vfs-cache-mode=writes"
            "--write-back-cache"
        )
        until "$RCLONE" mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$@"; do
            _MountPoint
            _unmount
            echo "rclone mount for $MPOINT crashed with exit code $?.  Respawning.."
            sleep 2
        done
    }

    _NormalMount() { # Mount Rclone without any caching.
        until "$RCLONE" mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}"; do
            _MountPoint
            _unmount
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
            _purge
            ;;
        -m | --mount)
            _NormalMount
            ;;
        -u | --unmount)
            _unmount
            ;;
        -c | --cache)
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
