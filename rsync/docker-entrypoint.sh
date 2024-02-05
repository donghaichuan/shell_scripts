#!/usr/bin/env sh
rsync --daemon --config=/etc/rsyncd.conf --no-detach --port=873 &
sleep 5
tail -f /var/log/rsync.log