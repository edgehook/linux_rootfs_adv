#!/bin/bash

###########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
###########################################################################

##-------------------------------------------------------------------------
OTA_PATH="/oem/update_ota"

##-------------------------------------------------------------------------
# exec update after shell
echo "$0 begin ..."
if [ -f "$OTA_PATH/update_flag" ]; then
    echo "Exist updat flag"
    rm $OTA_PATH/update_flag
    if [ -f "$OTA_PATH/PostUpdate.sh" ]; then
        echo "Exec PostUpdate.sh"
        $OTA_PATH/PostUpdate.sh
        rm $OTA_PATH/PostUpdate.sh
    fi
fi
echo "$0 end"