#!/bin/sh

## modemmanager can't  see rm500Q usb serial at POR.
## we neet to re-scan the modems by modemmanager.
{
 mmcli --scan-modems
 sleep 2
# mmcli --scan-modems
}&
