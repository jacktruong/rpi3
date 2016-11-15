#!/bin/bash
if [ -f "/home/kiosk/url.conf" ]; then
  source "/home/kiosk/url.conf"
else
  export PING="https://google.ca"
fi

/usr/bin/wget -q -O /dev/null $PING

exit