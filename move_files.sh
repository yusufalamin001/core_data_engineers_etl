#!/bin/bash

# Moves all .csv and .json files from a source folder into json_and_CSV.

SOURCE_DIR="source_files"
DEST_DIR="json_and_CSV"

echo "Starting file move"

mkdir -p "$DEST_DIR"

# without nullglob, a pattern with no matches (e.g. no .json files) is passed
# through as the literal string "*.json" and mv fails looking for that file
shopt -s nullglob

FILES=("$SOURCE_DIR"/*.csv "$SOURCE_DIR"/*.json)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No CSV or JSON files found in $SOURCE_DIR."
else
    for file in "${FILES[@]}"; do
        mv "$file" "$DEST_DIR/"
        echo "Moved $(basename "$file")"
    done
    echo "Done. Moved ${#FILES[@]} file(s) to $DEST_DIR."
fi

# reset in case this script ever gets sourced instead of run as its own process
shopt -u nullglob
