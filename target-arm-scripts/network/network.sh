#!/bin/bash

echo " --- " > /dev/tty1
echo "IPconfig data:" > /dev/tty1
ifconfig | grep "inet addr:" > /dev/tty1
echo " --- " > /dev/tty1
