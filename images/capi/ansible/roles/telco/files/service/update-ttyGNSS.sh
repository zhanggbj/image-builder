#!/bin/bash

device_name=$(ls /dev/ttyGNSS* 2>/dev/null)

if [ -n "$device_name" ]; then
    echo "Device name: $device_name"

    # Extract the part after /dev/ttyGNSS_
    part=$(echo "$device_name" | sed -n 's|/dev/ttyGNSS_\(.*\)|\1|p')

    # Replace the device name in the configuration file
    sed -i "s|/dev/ttyGNSS_.*|/dev/ttyGNSS_$part|" /etc/ts2phc.conf

    echo "ts2phc.conf file updated."
else
    echo "No device found with name starting with 'ttyGNSS'"
fi