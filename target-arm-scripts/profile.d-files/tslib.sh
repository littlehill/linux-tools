#!/bin/sh

if [ -e /dev/input/touchscreen0 ]; then
    TSLIB_TSDEVICE=/dev/input/touchscreen0

    export TSLIB_TSDEVICE
fi

export TSLIB_CALIBFILE=/etc/pointercal
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="invertx"

