@ECHO OFF

set "LOGFILE=$HOME/logs/remote-mount.log"
set "REMOTE=omg-ROOTcache:"
set "MPOINT=R:"
set "rclonecacheARGS=--cache-tmp-upload-path=$HOME/.cache/rclone/cache-backend --cache-chunk-path=$HOME/.cache/rclone/cache-backend --cache-chunk-size=1M --cache-total-chunk-size=100G --cache-chunk-clean-interval=1m --cache-info-age=12h --cache-read-retries=10 --cache-workers=20 --cache-db-path=$HOME/.cache/rclone/cache-backend --cache-writes --cache-tmp-wait-time=10s"
set "rcloneARGS=--allow-other --fuse-flag=sync_read --buffer-size=256 --attr-timeout=10s --timeout=5s --max-read-ahead=1M --cache-dir=$HOME/.cache/rclone --dir-cache-time=5m -vvv --poll-interval=40s --contimeout=5s --stats=10s --cache-db-purge"
rclone mount %REMOTE% %MPOINT% %rcloneARGS% %rclonecacheARGS%
