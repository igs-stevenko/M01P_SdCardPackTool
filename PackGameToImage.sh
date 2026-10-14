#!/bin/bash

source ./utilities.sh


check "mkfs.ext4 $DOWNLOAD_IMG"
check "mount $DOWNLOAD_IMG mnt"
check "rm -rf mnt/*"
check "mkdir mnt/update"
check "cp -af out_update/* mnt/update/"

if [ -f "$TMP_TAR/OTA_Service.xml" ]; then
	cp $TMP_TAR/OTA_Service.xml mnt/update/
fi

if [ -f "$TMP_TAR/otaprop.properties" ]; then
	cp $TMP_TAR/otaprop.properties mnt/update/
fi

check "umount mnt"
