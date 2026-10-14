#!/bin/bash

TARGET_DIR="$1"
OUTPUT_FILE="$2"
HMAC_KEY="$3"

if [ -z "$TARGET_DIR" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$HMAC_KEY" ]; then
    echo "Usage: $0 <target_dir> <output_file> <hmac_key>"
    exit 1
fi

OUTPUT_FILE="$(cd "$(dirname "$OUTPUT_FILE")" 2>/dev/null && pwd)/$(basename "$OUTPUT_FILE")"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

cd "$TARGET_DIR" || exit 1

# 收集所有 hash 用於計算 total
ALL_HASHES=""

# 開始寫 JSON
echo "{" > "$OUTPUT_FILE"

# APK 區塊 - 直接在目標資料夾根目錄找 *.apk
APK_FILE=$(find . -maxdepth 1 -name "*.apk" -type f 2>/dev/null | head -1)
if [ -n "$APK_FILE" ]; then
    APK_NAME=$(basename "$APK_FILE")
    APK_HASH=$(openssl dgst -sha1 -hmac "$HMAC_KEY" "$APK_FILE" 2>/dev/null | awk "{print \$NF}")
    ALL_HASHES+="$APK_HASH"
    
    echo "  \"apk\": {" >> "$OUTPUT_FILE"
    echo "    \"name\": \"$APK_NAME\"," >> "$OUTPUT_FILE"
    echo "    \"hash\": \"$APK_HASH\"" >> "$OUTPUT_FILE"
    echo "  }," >> "$OUTPUT_FILE"
else
    echo "Warning: No APK found in $TARGET_DIR"
fi

# Media 區塊 - 只處理 media/ 資料夾
echo "  \"media\": [" >> "$OUTPUT_FILE"

if [ -d "./media" ]; then
    first=true
    while IFS= read -r -d "" file; do
        # 相對於 media/ 的路徑
        rel_path="${file#./media/}"
        file_size=$(stat -c%s "$file")
        file_hash=$(openssl dgst -sha1 -hmac "$HMAC_KEY" "$file" 2>/dev/null | awk "{print \$NF}")
        ALL_HASHES+="$file_hash"
        
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$OUTPUT_FILE"
        fi
        
        echo -n "    {" >> "$OUTPUT_FILE"
        echo -n "\"path\": \"$rel_path\", " >> "$OUTPUT_FILE"
        echo -n "\"size\": $file_size, " >> "$OUTPUT_FILE"
        echo -n "\"hash\": \"$file_hash\"" >> "$OUTPUT_FILE"
        echo -n "}" >> "$OUTPUT_FILE"
    done < <(find ./media -type f -print0 | sort -z)
else
    echo "Warning: No media/ folder found in $TARGET_DIR"
fi

echo "" >> "$OUTPUT_FILE"
echo "  ]," >> "$OUTPUT_FILE"

# Total hash (所有 hash 串接後再做一次 HMAC)
TOTAL_HASH=$(echo -n "$ALL_HASHES" | openssl dgst -sha1 -hmac "$HMAC_KEY" 2>/dev/null | awk "{print \$NF}")
echo "  \"total\": \"$TOTAL_HASH\"" >> "$OUTPUT_FILE"

echo "}" >> "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"
