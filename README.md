# Linux and Git Project: CoreDataEngineers ETL

A Bash-only ETL pipeline built as part of the CDE Bootcamp Linux and Git assignment. Scenario: newly hired as a Data Engineer at CoreDataEngineers, whose infrastructure runs on Linux, tasked with managing data infrastructure and version control.

## What's in this repo

- `etl.sh`: downloads a CSV, cleans and reshapes it, and loads the result into a Gold folder
- `move_files.sh`: moves all CSV and JSON files from a source folder into `json_and_CSV`
- A cron job (not tracked in this repo, documented below) that runs `etl.sh` daily at midnight

## etl.sh

### Extract

Downloads the source CSV from a URL stored in an environment variable (`SOURCE_URL`), so the source can change without touching the script's logic. The `raw` folder is created with `mkdir -p` if it doesn't already exist, which also means the script doesn't error out on repeat runs. After downloading, the script checks the exit code of `wget` directly, since a failed download can still leave no file behind, and separately confirms the file actually exists in `raw` before moving on.

### Transform

Two things happen here, in order.

First, `sed` fixes the header row only, line 1, nothing else: `Variable_code` becomes `variable_code`, and `Year` becomes `year`, matching the exact casing the assignment lists the target columns in.

Second, column selection uses `awk` with `FPAT` instead of plain comma splitting. This file has quoted fields containing commas inside them (for example, `Variable_name` values like `"Sales, government funding, grants and subsidies"`), so a naive `cut` or `awk -F','` would miscount columns on those rows. `FPAT` tells awk what a field looks like instead of what separates one, so a whole quoted chunk is treated as a single field even with commas inside it. This needs `gawk` specifically (the default `awk` on WSL and most Linux distros), not every `awk` implementation supports `FPAT`.

The final columns are selected and reordered to match the assignment's order (`year, Value, Units, variable_code`), saved as `2023_year_finance.csv` into a `Transformed` folder, with the same create-then-confirm pattern as Extract.

### Load

Copies the transformed file into a `Gold` folder, again confirming it landed there before the script reports success.

## Cron scheduling

The script is scheduled with:
```
0 0 * * * /home/subzero/core_data_engineers_etl/etl.sh >> /home/subzero/core_data_engineers_etl/cron.log 2>&1
```
This runs daily at midnight. The absolute path is used for both the script and the log file, since cron does not run jobs from the directory you happen to be in when you set it up. Output and errors are both redirected into `cron.log` (`2>&1` sends stderr to the same place as stdout), so a failed run at midnight is still visible later rather than silently lost.

**WSL-specific note:** WSL does not start background services like cron automatically the way a full Linux server does. If cron doesn't appear to be firing, check with `sudo service cron status`, and start it with `sudo service cron start` if needed. This does not persist across a WSL restart, it needs to be started again manually each time.

`cron.log` is gitignored, since it's generated output from running the script, not something meant to be version controlled.

## move_files.sh

Moves every `.csv` and `.json` file from a source folder into `json_and_CSV`. Uses `shopt -s nullglob` so that a missing file type doesn't cause an error, without it, a pattern like `*.json` with zero matches would be passed through as the literal text `*.json` and fail trying to move a file that doesn't exist. With `nullglob` enabled, a pattern with no matches simply contributes nothing to the file list instead. The script reports how many files were moved, or explicitly states that none were found, and works correctly whether there are zero, one, or several files of either type.

## Folder structure

`raw`, `Transformed`, `Gold`, `json_and_CSV`, and `source_files` are all gitignored. Each one holds either generated output or throwaway test data, not hand-written work, so they get recreated automatically whenever the scripts run rather than being committed.

## Git workflow

Each piece of work (the ETL script, the file-mover script, supporting fixes) was developed on its own feature branch and merged into `main` through a pull request, rather than committing everything directly to `main`.

## Running this yourself

```
chmod +x etl.sh move_files.sh
./etl.sh
./move_files.sh
```
`SOURCE_DIR` inside `move_files.sh` should be pointed at whatever folder holds the CSV/JSON files you want moved.
