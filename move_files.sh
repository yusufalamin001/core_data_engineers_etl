#!/bin/bash

# Moves all .csv and .json files from a source folder into json_and_CSV.
# Handles zero, one, or many files of either type without erroring out.

SOURCE_DIR="source_files"
DEST_DIR="json_and_CSV"

echo "Starting file move"

mkdir -p "$DEST_DIR"

# nullglob makes a pattern with no matches expand to nothing instead of
# being treated as a literal string like "*.json", which would otherwise
# cause mv to fail looking for a file that doesn't exist.
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

# turn nullglob back off so it doesn't affect any other script that
# might source this file or run after it in the same shell
shopt -u nullglob
