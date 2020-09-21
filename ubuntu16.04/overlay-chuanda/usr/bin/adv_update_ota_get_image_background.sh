#!/bin/bash

###########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
###########################################################################

##-------------------------------------------------------------------------
# error code

# update process 
##-------------------------------------------------------------------------
OTA_PATH="/oem/update_ota"
OTA_ERR_CODE="${OTA_PATH}/update_err_code"
OTA_UPDATE_IMAGE_SIZE="${OTA_PATH}/update_image_size"

TIME_OUT=60
##-------------------------------------------------------------------------
pre_size=0
now_size=0
count=0

total_size=`cat $OTA_UPDATE_IMAGE_SIZE`

while :
do
    UPDATE_SERVICE="adv_update_ota_get_image.sh"
    UPDATE_PROCESS=`ps -ef | grep "$UPDATE_SERVICE" | grep -v 'grep'`
    UPDATE_PROCESS_COUNT=`echo $UPDATE_PROCESS | grep -c "$UPDATE_SERVICE"`
    if [ "$UPDATE_PROCESS_COUNT" == "0" ]; then
        echo "Info : $UPDATE_SERVICE process exit!"
        exit 0
    fi
    
    if [ ! -f "/userdata/update.img" ]; then
        now_size=0
    else
        now_size=`ls -al "/userdata/update.img" |  awk '{print $5}'`
    fi
    
    if [ "$now_size" == "$total_size" ]; then
        break
    fi
    if [ "$pre_size" == "$now_size" ]; then
        let count=count+1
        if [ $count -gt $TIME_OUT ]; then
            echo "Fail : $UPDATE_SERVICE get update.img timeout!"
            adv_update_ota_cancel.sh
            echo $ERR_DOWNLOAD_TIMEOUT > $OTA_ERR_CODE
            exit 0
        fi        
    else
        let count=0
        pre_size=$now_size
    fi

    sleep 1
done

