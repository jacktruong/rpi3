#!/bin/bash
if [ -f "/home/kiosk/.location" ]; then
	source /home/kiosk/.location
else
	export LOCATION="test"
fi

/usr/bin/wget -q -O - --spider https://www.eng.uwaterloo.ca/~enginfo/enginfo3/heartbeat/enginfo/${LOCATION}

exit