#!/bin/bash

source ./utilities.sh

export IMAGE_FILES=$1
export GAME_FILES=$2
export DOWNLOAD_IMG=download.img
export IMAGE_IN=images_in
export IMAGE_OUT=images_out
export FLASH_TYPE=""
export TMP_TAR=tmp_tar
export APK_NAME=""
export INPUT_NAME=""
export OUTPUT_NAME=""
export DOWNLOAD_SIZE=""

export ONLY_UPDATE_SYSTEM="false"


INPUT_NAME="${IMAGE_FILES%%.tar.gz}"
echo "INPUT_NAME=$INPUT_NAME"
OUTPUT_NAME="${INPUT_NAME}_sdcard"
echo "OUTPUT_NAME=$OUTPUT_NAME"

if [ -z "$GAME_FILES" ]; then
	ONLY_UPDATE_SYSTEM="true"
fi


rm -rf $IMAGE_IN/*
rm -rf $TMP_TAR/*
rm -rf $IMAGE_OUT/*

check "tar zxf $IMAGE_FILES -C $IMAGE_IN"
DOWNLOAD_SIZE=`cat $IMAGE_IN/download_size.txt`
echo "DOWNLOAD_SIZE=$DOWNLOAD_SIZE"


if [ "$ONLY_UPDATE_SYSTEM" = "false" ]; then

	rm $DOWNLOAD_IMG > /dev/null 2>&1

	if [ $DOWNLOAD_SIZE = "1073741824" ]; then
		dd if=/dev/zero of=$DOWNLOAD_IMG bs=1024 count=1048576
	elif [ $DOWNLOAD_SIZE = "2147483648" ]; then
		dd if=/dev/zero of=$DOWNLOAD_IMG bs=1024 count=2097152
	elif [ $DOWNLOAD_SIZE = "4294967296" ]; then
		dd if=/dev/zero of=$DOWNLOAD_IMG bs=1024 count=4194304
	elif [ $DOWNLOAD_SIZE = "8589934592" ]; then
		dd if=/dev/zero of=$DOWNLOAD_IMG bs=1024 count=8388608
	elif [ $DOWNLOAD_SIZE = "11811160064" ]; then
		dd if=/dev/zero of=$DOWNLOAD_IMG bs=1024 count=11534336
	elif [ $DOWNLOAD_SIZE = "16106127360" ]; then
		dd if=/dev/zero of=$DOWNLOAD_IMG bs=1024 count=15728640
	else
		echo "DOWNLOAD_SIZE not match !!!"
		exit 1
		fi

	if [ ! -f "$DOWNLOAD_IMG" ]; then
		echo "$DOWNLOAD_IMG is not exist !!!"
		exit 1
	fi

	# 要更新遊戲
	check "unzip $GAME_FILES -d $TMP_TAR"

	#製作baseline.json
	check "./gen_baseline.sh tmp_tar/ ./baseline.json 2b3181a1b169235178b6664ba1db7434848f2e71"
	
	APK_NAME=$(basename "`ls ${TMP_TAR}/*.apk`")
	echo "APK_NAME=$APK_NAME"
	mv $TMP_TAR/$APK_NAME GameApk/game.apk
	mv $TMP_TAR/media/* Media/
	check "./PackUpdateGamePackage.sh"
	check "./PackGameToImage.sh"
	mv $DOWNLOAD_IMG $IMAGE_IN
	
fi

check "./mkupdate.sh"

check "mv $IMAGE_OUT/update.img $IMAGE_OUT/${OUTPUT_NAME}.img"

check "./remove.sh"
