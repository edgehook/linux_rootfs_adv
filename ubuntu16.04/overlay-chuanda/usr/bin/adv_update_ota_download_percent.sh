#!/bin/bash

###########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
###########################################################################

##-------------------------------------------------------------------------
# error code
ERR_PROCESS_IS_RUNNING="-1"
ERR_PROJECT_CONFIG="-2"
ERR_FTP_CONFIG="-3"
ERR_UPDATE_LIST="-4"
ERR_VERSION="-5"
ERR_DOWNLOAD_IMAGE="-6"
ERR_DOWNLOAD_TIMEOUT="-7"

ERR_UPDATE_FLOW="-20"
##-------------------------------------------------------------------------
OTA_PATH="/oem/update_ota"
OTA_ERR_CODE="${OTA_PATH}/update_err_code"

OTA_UPDATE_IMAGE_SIZE="${OTA_PATH}/update_image_size"
OTA_UPDATE_DOWNLOAD_PERCENT="${OTA_PATH}/update_download_percent"
##-------------------------------------------------------------------------
if [ ! -f "$OTA_UPDATE_IMAGE_SIZE" ]; then
    echo "Fail : Please Check image first"
    echo "$ERR_UPDATE_FLOW" > $OTA_ERR_CODE
    exit 1
fi

UPDATE_SERVICE="adv_update_ota_get_image.sh"
UPDATE_PROCESS=`ps -ef | grep "$UPDATE_SERVICE" | grep -v 'grep'`
UPDATE_PROCESS_COUNT=`echo $UPDATE_PROCESS | grep -c "$UPDATE_SERVICE"`
if [ "$UPDATE_PROCESS_COUNT" == "0" ]; then
    echo "Fail : $UPDATE_SERVICE process isn't running!"
    echo "$ERR_UPDATE_FLOW" > $OTA_ERR_CODE
    exit 1
fi

if [ ! -f "/userdata/update.img" ]; then
    get_size=0
else
    get_size=`ls -al "/userdata/update.img" |  awk '{print $5}'`
fi

total_size=`cat $OTA_UPDATE_IMAGE_SIZE`

percent=`echo "$get_size $total_size"|awk '{print int($1*100/$2)}'`

echo $percent > $OTA_UPDATE_DOWNLOAD_PERCENT