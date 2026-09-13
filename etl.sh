#!/bin/bash

# ETL for the annual enterprise survey CSV, extract, transform, load into Gold.

# URL as an env var so the source can change without touching the logic below
export SOURCE_URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"

RAW_DIR="raw"
TRANSFORMED_DIR="Transformed"
GOLD_DIR="Gold"
RAW_FILE="$RAW_DIR/annual-enterprise-survey-2023-financial-year-provisional.csv"
TRANSFORMED_FILE="$TRANSFORMED_DIR/2023_year_finance.csv"

echo "Starting ETL pipeline"

# Extract

mkdir -p "$RAW_DIR"

echo "Downloading source file..."
wget -q -O "$RAW_FILE" "$SOURCE_URL"

if [ $? -ne 0 ]; then
    echo "Download failed, exiting."
    exit 1
fi

if [ -f "$RAW_FILE" ]; then
    echo "Saved to $RAW_FILE"
else
    echo "Something's off, file isn't in $RAW_DIR."
    exit 1
fi


# Transform

mkdir -p "$TRANSFORMED_DIR"

# Year -> year matches the exact casing the brief lists the columns in
sed -e '1s/Variable_code/variable_code/' -e '1s/Year/year/' "$RAW_FILE" > "$RAW_DIR/renamed_temp.csv"

# Variable_name and Industry_code_ANZSIC06 have commas inside quotes, so
# plain comma-splitting miscounts columns. FPAT (gawk) treats a whole quoted
# chunk as one field. Reordering fields 1,9,5,6 to year,Value,Units,variable_code.
awk 'BEGIN{FPAT="([^,]+)|(\"[^\"]+\")"; OFS=","} {print $1, $9, $5, $6}' "$RAW_DIR/renamed_temp.csv" > "$TRANSFORMED_FILE"

rm "$RAW_DIR/renamed_temp.csv"

if [ -f "$TRANSFORMED_FILE" ]; then
    echo "Transformed file saved to $TRANSFORMED_FILE"
else
    echo "Transform step failed, no output file found."
    exit 1
fi

# Load

mkdir -p "$GOLD_DIR"
cp "$TRANSFORMED_FILE" "$GOLD_DIR/"

if [ -f "$GOLD_DIR/2023_year_finance.csv" ]; then
    echo "Loaded into $GOLD_DIR"
else
    echo "Load step failed, file not in $GOLD_DIR."
    exit 1
fi

echo "ETL pipeline done"
