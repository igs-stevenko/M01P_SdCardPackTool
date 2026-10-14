#!/bin/bash

source ./utilities.sh

set -euo pipefail

KEYFILE=Key/keyfile.txt
IVFILE=Key/ivfile.txt

PLAIN_FILE=Resource.zip
ENCRYPTED_FILE=update.zip
INFO_FILE=info.txt
PF_FILE=PF.txt

RESOURCE_DIR=Resource
MEDIA_SOURCE_DIR=Media
GAME_SOURCE_DIR=GameApk
TEMP_DIR=./Temp
OUT_DIR=./out_update

BASELINE_FILE=baseline.json

FILENAME=$IMAGE_FILES

BASENAME="${FILENAME%.tar.gz}"
GAME_NAME=$(echo "$BASENAME" | cut -d'_' -f4)

BUILD_TYPE=$(echo "$FILENAME" | cut -d'_' -f3)
echo "$BUILD_TYPE"  # 輸出: dev

#echo "提取字串: $GAME_NAME"

# SHA-256 → 32 bytes (64 hex chars)
HASH_HEX=$(printf '%s' "$GAME_NAME" | sha256sum | cut -d' ' -f1)

#echo "SHA-256 hex: $HASH_HEX"
#echo ""

# 切成兩半（各 32 hex chars = 16 bytes）
HALF1="${HASH_HEX:0:16}"
HALF2="${HASH_HEX:16:16}"


if [[ "$BUILD_TYPE" == "rel" || "$BUILD_TYPE" == "rel-Sdcard" ]]; then
	# 如果是產品碟，則使用專案key，如果是開發碟則使用原本的key
	# 每個 hex 字元轉成 ASCII hex（xxd -p 會把每個字元變成兩位 hex）
	KEY=$(printf '%s' "$HALF1" | xxd -p | tr -d '\n')
	IV=$(printf '%s'  "$HALF2" | xxd -p | tr -d '\n')
else
	KEY=66326138623065376339643334313035
	IV=37663365396430613162356338653266
fi

echo "$KEY"
echo "$IV"



mkdir -p ${TEMP_DIR}
rm -rf ${TEMP_DIR}/*

mkdir -p ${TEMP_DIR}/${RESOURCE_DIR}

mkdir -p ${OUT_DIR}/
rm -rf ./${OUT_DIR}/*

check "cp -af ${MEDIA_SOURCE_DIR} ${GAME_SOURCE_DIR}/* ${TEMP_DIR}/${RESOURCE_DIR}"

# 查看baseline.json是否存在
if [ -f "$BASELINE_FILE" ]; then
    echo "$BASELINE_FILE檔案存在"
	check "cp -af ${BASELINE_FILE} ${TEMP_DIR}/${RESOURCE_DIR}"
else
    echo "$BASELINE_FILE檔案不存在"
fi


cd ${TEMP_DIR}
check "zip -r ${PLAIN_FILE} ${RESOURCE_DIR}"

cd -
#openssl enc -aes-128-cbc -K 31313131313131313131313131313131 -iv 32323232323232323232323232323232 -in update.zip -out enc_update.zip
check "openssl enc -aes-128-cbc -K $KEY -iv $IV -in ${TEMP_DIR}/${PLAIN_FILE} -out ${OUT_DIR}/${ENCRYPTED_FILE}"
MD5SUM=`md5sum ${OUT_DIR}/${ENCRYPTED_FILE} | sed 's/ .*$//' `
echo $MD5SUM > ${OUT_DIR}/${INFO_FILE}
check "md5sum ${TEMP_DIR}/$PLAIN_FILE | awk '{print \$1}' > ${OUT_DIR}/${PF_FILE}"


