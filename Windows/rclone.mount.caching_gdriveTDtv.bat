@ECHO OFF

set "LOGFILE=%HOME%\logs\rclone-oriongrimm1-TDtvCache.log"
set "REMOTE=oriongrimm1-TDtvCACHE:"
set "MPOINT=T:"
set "rcloneARGS=--allow-other --contimeout=5s --log-file=%LOGFILE% --log-level=DEBUG --stats=10s --timeout=5s --attr-timeout=1s --buffer-size=0M --cache-chunk-size=10M --cache-db-path=%HOME%\.cache\rclone\rcache --cache-db-purge --cache-info-age=10m --cache-total-chunk-size=10G --cache-workers=8 --cache-writes --dir-cache-time=4m"

rclone mount %REMOTE% %MPOINT% %rcloneARGS%
