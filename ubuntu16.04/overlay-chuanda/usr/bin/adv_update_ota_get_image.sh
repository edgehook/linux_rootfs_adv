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

OTA_UPDATE_CHECK_FLAG="${OTA_PATH}/update_check_flag"

UDISK_MOUNT_PATH="/media/$USER/UPDATE"

FTP_CONFIG_FILE="/etc/ftp_ota.conf"

WAIT_TIME=10
TRY_COUNT=10

if [ ! -d "$OTA_PATH" ]; then
    mkdir -p $OTA_PATH
fi
##-------------------------------------------------------------------------
UPDATE_RESOURCE=FTP
if [ -d "$UDISK_MOUNT_PATH" ]; then
    UPDATE_RESOURCE=UDISK
fi

##-------------------------------------------------------------------------
## get FTP configuration from FTP_CONFIG_FILE.
##-------------------------------------------------------------------------
function get_ftp_configuration()
{
    echo "Get ftp configuration from $FTP_CONFIG_FILE"
    FTP_SERVER_IP=`grep ftpserver_ip $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_USER=`grep ftpserver_user $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PASSWORD=`grep ftpserver_passwd $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PATH=`grep ftpserver_dirname $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`

    echo "FTP_SERVER_IP : $FTP_SERVER_IP"
    echo "FTP_USER      : $FTP_USER"
    echo "FTP_PASSWORD  : $FTP_PASSWORD"
    echo "FTP_PATH      : $FTP_PATH"
}

function ftp_get_image()
{
    cd /userdata

    pftp -v -n ${FTP_SERVER_IP} <<-EOF
        user "${FTP_USER}" "${FTP_PASSWORD}"
        prompt
        binary
        pwd
        cd $FTP_PATH
        mget update.img.md5
        mget update.img
        close
        quit
	EOF

    sync
}

function ftp_get_update_shell()
{
    cd $OTA_PATH

    pftp -v -n ${FTP_SERVER_IP} <<-EOF
        user "${FTP_USER}" "${FTP_PASSWORD}"
        prompt
        binary
        pwd
        cd $FTP_PATH
        mget PreUpdate.sh
        mget PostUpdate.sh
        close
        quit
	EOF

    sync

    if [ -f "PreUpdate.sh" ]; then
        chmod +x PreUpdate.sh
    fi

    if [ -f "PostUpdate.sh" ]; then
        chmod +x PostUpdate.sh
    fi
}

function udisk_get_image()
{
    cd /userdata
    cp $UDISK_MOUNT_PATH/update.img.md5 ./
    cp $UDISK_MOUNT_PATH/update.img ./
    sync
}

function udisk_get_update_shell()
{
    cd $OTA_PATH

    cp $UDISK_MOUNT_PATH/PreUpdate.sh ./
    cp $UDISK_MOUNT_PATH/PostUpdate.sh ./
    sync
    chmod +x PreUpdate.sh
    chmod +x PostUpdate.sh
}

function update_clean()
{
    if [ -f "/userdata/update.img" ]; then
        rm /userdata/update.img
    fi

    if [ -f "/userdata/update.img.md5" ]; then
        rm /userdata/update.img.md5
    fi

    if [ ! -d "$OTA_PATH" ]; then
        mkdir -p $OTA_PATH
    fi
    rm -rf $OTA_PATH/*
    sync
}

function update_exit()
{
    update_clean
    echo "$0" > $OTA_ERR_CODE
    exit 1
}

# --------------------------------------------------------- #

#check OK
if [ ! -f "$OTA_UPDATE_CHECK_FLAG" ]; then
    echo "Fail : Please Check image first"
    update_exit $ERR_UPDATE_FLOW
else
    rm $OTA_UPDATE_CHECK_FLAG
fi

# get update image
adv_update_ota_get_image_background.sh &

echo "Info : Get update image and shell begin"
if [ "$UPDATE_RESOURCE" == "UDISK" ]; then
    udisk_get_update_shell
    udisk_get_image
else
    get_ftp_configuration
    ftp_get_update_shell
    ftp_get_image
fi

for p_pid in `ps -ef | grep 'adv_update_ota_get_image_background.sh' | grep -v grep | awk '{print $2}'`
do
    echo "$p_pid"
    kill -9 $p_pid
done
echo "Info : Get update image and shell done"

# check update image
echo "Info : Check md5 begin"
if [ ! -f "/userdata/update.img" ]; then
    echo "Fail : Don't exist update.img in $UPDATE_RESOURCE"
        update_exit $ERR_DOWNLOAD_IMAGE
fi

if [ ! -f "/userdata/update.img.md5" ]; then
    echo "Fail : Don't exist update.img.md5 in $UPDATE_RESOURCE"
    update_exit $ERR_DOWNLOAD_IMAGE
fi

# check md5
md5src=`cat /userdata/update.img.md5 | awk '{print $1}'`
md5des=`md5sum /userdata/update.img | awk '{print $1}'`
if [ "$md5src" != "$md5des" ]; then
    echo "Fail: Check md5 fail"
    update_exit $ERR_DOWNLOAD_IMAGE
fi

echo "Info : Check md5 done"
rm /userdata/update.img.md5
sync

# before update shell
if [ -f "$OTA_PATH/PreUpdate.sh" ]; then
    echo "Info : Exec PreUpdate.sh"
    $OTA_PATH/PreUpdate.sh
    if [ -f "$OTA_PATH/PreUpdate.sh" ]; then
        rm $OTA_PATH/PreUpdate.sh
    fi
fi
sync

# update image
echo "Info : Reboot to recovery mode to update"
/usr/bin/update-ota
