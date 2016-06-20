#!/bin/sh

#sleep 1
#cpu switch off 1-3 cores 
echo 0 >> /sys/devices/system/cpu/cpu1/online
echo 0 >> /sys/devices/system/cpu/cpu2/online
echo 0 >> /sys/devices/system/cpu/cpu3/online

echo "CPU cores 1-3 disabled" >> /dev/tty1

exit 0
