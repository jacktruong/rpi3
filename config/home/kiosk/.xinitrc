#!/bin/bash
# X session initialization script; configures and initiates kiosk user's X
# session
#
# Created by Desmond Cox
# Original by David Collie
# Modified Dec. 15, 2008, by SMC to just run Opera, but with two screen savers,
#   one pre-login screensaver and one after user activity detected 
# Modified October 26 by JT to work with Firefox and fix the 'user-wakeup' script. Also to disable screen blanking -- really not needed.

# sleep in case things aren't loaded yet, like networking

/bin/sleep 1

# prevent screen blanking
/usr/bin/xset s off
/usr/bin/xset dpms 0
/usr/bin/xset s noblank
/usr/bin/xset -dpms

# hide the mouse cursor
/usr/bin/unclutter -noevents -idle 1 &

# kill former instances of emerge, if they exist
/usr/bin/killall perl

# load the window manager
/usr/bin/icewmbg-lite &
/usr/bin/icewm-lite &

# runs the emerge client
/usr/bin/perl /home/kiosk/emerge.pl &

/bin/bash /home/kioks/startup.sh

#script exits after chromium closes and loops back to .bash_profile