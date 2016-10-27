#!/bin/bash
if [ -f "/home/kiosk/.location" ]; then
	source /home/kiosk/.location
else
	export LOCATION="test"
fi

/usr/bin/wget -q -O /dev/null https://www.eng.uwaterloo.ca/~enginfo/api/heartbeat/enginfo/${LOCATION}

exit