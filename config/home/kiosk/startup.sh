#!/bin/bash

if [ -a "/home/kiosk/app.conf" ]
  then
    APP="`cat /home/kiosk/app.conf`"
  else
    APP="file:///home/kiosk/welcome.html"
fi

if [ -a "/home/kiosk/ping.conf" ]
  then
    PING="`cat /home/kiosk/ping.conf`"
  else
    PING="https://google.ca"
fi

/usr/bin/wget -q -O /dev/null "$PING"
firefox-esr "$APP"