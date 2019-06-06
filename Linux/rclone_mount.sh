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
    RCLONE_REMOTES_TYPE="drive"
    RCLONE_REMOTES_SCOPE="drive"
    MPOINT="$HOME/cloud/" # Path to your mount folder.

    # Remotes:
    REMOTE_0="UNION"
    REMOTE_1="TV"
    REMOTE_1_TD="0AEFojj-9Uk9PVA"
    REMOTE_2="MOVIES"
    REMOTE_2_TD="0ABEto_k9PVA"

    export RCLONE_CONFIG_"$REMOTE_0"_TYPE="union"
    export RCLONE_CONFIG_"$REMOTE_0"_REMOTES="$REMOTE_1: $REMOTE_2:"
    export RCLONE_CONFIG_"$REMOTE_1"_TYPE="$RCLONE_REMOTES_TYPE"
    export RCLONE_CONFIG_"$REMOTE_1"_SCOPE="$RCLONE_REMOTES_SCOPE"
    export RCLONE_CONFIG_"$REMOTE_1"_TEAM_DRIVE="$REMOTE_1_TD"
    export RCLONE_CONFIG_"$REMOTE_2"_TYPE="$RCLONE_REMOTES_TYPE"
    export RCLONE_CONFIG_"$REMOTE_2"_SCOPE="$RCLONE_REMOTES_SCOPE"
    export RCLONE_CONFIG_"$REMOTE_2"_TEAM_DRIVE="$REMOTE_2_TD"

    # Rclone and Service Accounts
    REMOTE="$REMOTE_0"      # Do not change this option. I use the advanced backend options for mounting.
    RCLONE="rclone" # Path to rclone. In most cases, it will be in your $PATH so you shouldnt need to change this.
    FRCLONE="$HOME/bin/rclone"
    SAKEYS="$HOME/keys/"

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
        if [ ! -d "$RCLONE_CACHE_DB_PATH" ]; then
            echo "Creating temp cache Location"
            mkdir -p "$RCLONE_CACHE_DB_PATH"
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
        #    "--allow-other"
        "--timeout=1h"
        "--tpslimit=10"
        "--tpslimit-burst=10"
        "-P"
        "-vvv"
        "--umask=002"
    )

    _RcloneCacheMount() { # Expects to used with the "Cache" remote.
        # Plex config
        export RCLONE_CACHE_PLEX_USERNAME="captainjackfalcon"
        export RCLONE_CACHE_PLEX_PASSWORD="GPcOBRffD4DFdEmPIT5-xdtc91TWAOw"
        export RCLONE_CACHE_PLEX_URL="https://192-131-44-121.testing.plex.direct:40891"

        export RCLONE_CACHE_DB_PATH="$HOME/.cache/rclone/cache-backend"
        export RCLONE_CACHE_CHUNK_PATH="$HOME/.cache/rclone/cache-backend"
        export RCLONE_CACHE_TMP_UPLOAD_PATH="$HOME/.cache/rclone/cache-tmp-upload"
        export RCLONE_CACHE_WRITES="true"
        export RCLONE_CACHE_WORKERS="8"
        export RCLONE_CACHE_DB_PURGE="true"
        export RCLONE_CACHE_INFO_AGE="100h"
        export RCLONE_CACHE_CHUNK_SIZE="32M"
        export RCLONE_CACHE_TMP_WAIT_TIME="1h"

        rclonecacheARGS=(
            "--buffer-size=0M"
            "--cache-remote=$REMOTE:"
            "--cache-chunk-total-size=500G"
            "--dir-cache-time=99h"
            "--drive-scope=drive"
            "--vfs-cache-mode=writes"
            "--write-back-cache"
        )
        COUNT_RM_FILES=$(find "$RCLONE_CACHE_DB_PATH" | wc -l)
        rm -rfv  "$RCLONE_CACHE_DB_PATH"/* | pv -l -s "$COUNT_RM_FILES"> /dev/null

        until "$RCLONEBINARY" mount ":cache:" "$MPOINT" "${rcloneARGS[@]}" "${rclonecacheARGS[@]}" "$@"; do
            _MountPoint
            _unmount
            echo ""
            echo ""
            echo "rclone mount for $MPOINT crashed with exit code $?.  Respawning.."
            echo ""
            echo ""
            sleep 2
        done
    }

    _NormalMount() { # Mount Rclone without any caching.
        until "$RCLONEBINARY" mount "$REMOTE" "$MPOINT" "${rcloneARGS[@]}"; do
            _MountPoint
            _unmount
            echo ""
            echo ""
            echo "rclone mount for $MPOINT crashed with exit code $?.  Respawning.."
            echo ""
            echo ""
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
            export RCLONEBINARY="$RCLONE"
            export RCLONE_DRIVE_SERVICE_ACCOUNT_FILE=$(find "$SAKEYS" -name "*.json" | sort -R | tail -1)
            _NormalMount
            ;;
        -u | --unmount)
            _unmount
            ;;
        -c | --cache)
            export RCLONEBINARY="$RCLONE"
            export RCLONE_DRIVE_SERVICE_ACCOUNT_FILE=$(find "$SAKEYS" -name "*.json" | sort -R | tail -1)
            _RcloneCacheMount
            ;;
        -f | --fcache)
            export RCLONEBINARY="$FRCLONE"
            export RCLONE_DRIVE_SERVICE_ACCOUNT_FOLDER="$SAKEYS"
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
