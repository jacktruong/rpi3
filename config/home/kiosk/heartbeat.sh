#!/bin/bash
if [ -a "/home/kiosk/ping.conf" ]; then
  PING="`cat /home/kiosk/ping.conf`"
else
  PING="https://google.ca"
fi

/usr/bin/wget -q -O /dev/null $PING

exit