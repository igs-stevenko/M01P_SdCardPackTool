#!/bin/bash
# Author: kenjc@rock-chips.com
# 2021-08-13

source ./utilities.sh

#readonly IMAGE_IN=images_in
#readonly IMAGE_OUT=images_out
#readonly FLASH_TYPE=""

readonly PACKAGE_FILE=package-file-tmp
STORAGE_ARG=""

pause() {
  echo "Press any key to quit:"
  read -n1 -s key
  exit 1
}


if [ ! -f "$IMAGE_IN/parameter.txt" ]; then
	echo "Error:No found parameter!"
#	pause
fi

echo "regenernate $PACKAGE_FILE..."
if [ -f "$PACKAGE_FILE" ]; then
    rm -rf $PACKAGE_FILE
fi
check "./gen-package-file.sh $IMAGE_IN > $PACKAGE_FILE"

if [ "$FLASH_TYPE" = "emmc" ]; then
  STORAGE_ARG="-storage:emmc"
fi

if [ "$FLASH_TYPE" = "scsi" ]; then
  STORAGE_ARG="-storage:scsi"
fi

echo "start to make update.img...$STORAGE_ARG"
check "./afptool -pack ./ $IMAGE_IN/update.img $PACKAGE_FILE || pause"
check "./rkImageMaker -RK3576 $IMAGE_IN/MiniLoaderAll.bin $IMAGE_IN/update.img $IMAGE_OUT/update.img -os_type:androidos $STORAGE_ARG || pause"

echo "## PACKAGE_FILE=$PACKAGE_FILE"
echo "## STORAGE_ARG=$STORAGE_ARG"


echo "Making update.img $STORAGE_ARG OK."
exit 0
