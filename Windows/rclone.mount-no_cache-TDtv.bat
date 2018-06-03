@ECHO OFF

set "LOGFILE=$HOME/logs/TDtv-mount.log"
set "REMOTE=oriongrimm1-TDtv:"
set "MPOINT=T:"
set "rcloneARGS=--allow-other --fuse-flag=sync_read --attr-timeout=10s --timeout=5s --max-read-ahead=1M -vvv --poll-interval=40s --contimeout=5s --stats=10s"
rclone mount %REMOTE% %MPOINT% %rcloneARGS%
