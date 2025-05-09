#!/bin/sh

# download wth-bundle.zip and extract earth-system-discipline.csv
# and generate topics-dropdown-list.csv
ZIP_URL="https://wmo-im.github.io/wis2-topic-hierarchy/wth-bundle.zip"
INPUT_FILE="earth-system-discipline.csv"
OUTPUT_FILE="topics-dropdown-list.csv"

# Check input argument
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target_directory>"
  exit 1
fi

TARGET_DIR="$1"

# Check directory exists and is writable
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR does not exist"
  exit 1
fi

if [ ! -w "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR is not writable"
  exit 1
fi

echo "Preparing topic list..."

TMPDIR=$(mktemp -d)
ZIPFILE="$TMPDIR/wth-bundle.zip"

# Download the zip file and check HTTP response
HTTP_STATUS=$(curl -s -L -w "%{http_code}" -o "$ZIPFILE" "$ZIP_URL")
if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Error: Failed to download zip file from $ZIP_URL (HTTP $HTTP_STATUS)"
  rm -rf "$TMPDIR"
  exit 1
fi

# Check if file is a valid zip (magic header: PK\x03\x04)
if ! head -c 4 "$ZIPFILE" | grep -q "$(printf 'PK\x03\x04')"; then
  echo "Error: Downloaded file is not a valid zip archive"
  rm -rf "$TMPDIR"
  exit 1
fi

# Extract CSV file from zip
unzip -p "$ZIPFILE" "$INPUT_FILE" > "$TMPDIR/$INPUT_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Error: $INPUT_FILE not found in zip file"
  rm -rf "$TMPDIR"
  exit 1
fi

# Check that file is not empty
if [ ! -s "$TMPDIR/$INPUT_FILE" ]; then
  echo "Error: $INPUT_FILE is empty"
  exit 1
fi

# Verify the first line is "Name"
HEADER=$(head -n 1 "$TMPDIR/$INPUT_FILE" | tr -d '\r')
if [ "$HEADER" != "Name" ]; then
  echo "Error: $INPUT_FILE does not start with Name"
  exit 1
fi

# loop through each line of the CSV file
# keep track of content of previous line
# get rid of non-leaf topics, by checking if the next line starts with the same string
# Ensure output is empty to start with
: > "$TMPDIR/$OUTPUT_FILE"

prev=""
while IFS= read -r current; do
    # remove carriage return and line break characters
    clean_current=$(echo "$current" | tr -d '\r\n')
    clean_prev=$(echo "$prev" | tr -d '\r\n')

    if [ -n "$prev" ]; then
        case "$clean_current" in
            "$clean_prev"/*) ;;  # If current starts with prev/, do not write prev
            *) echo "$prev" >> "$TMPDIR/$OUTPUT_FILE" ;;  # Otherwise, write prev to output
        esac
    fi
    prev="$current"
done < "$TMPDIR/$INPUT_FILE"

# Write the last line
[ -n "$prev" ] && echo "$prev" >> "$TMPDIR/$OUTPUT_FILE"

# Move the output file to the target directory
mv "$TMPDIR/$OUTPUT_FILE" "$TARGET_DIR/$OUTPUT_FILE"

# display the content of the output file
echo "Generated topic list:"
cat "$TARGET_DIR/$OUTPUT_FILE"

# Verify output file was created
if [ ! -f "$TARGET_DIR/$OUTPUT_FILE" ]; then
  echo "Error: $OUTPUT_FILE not found in $TARGET_DIR"
  exit 1
fi

# Cleanup
rm -rf "$TMPDIR"
echo "Topic list generated successfully at $TARGET_DIR/$OUTPUT_FILE"