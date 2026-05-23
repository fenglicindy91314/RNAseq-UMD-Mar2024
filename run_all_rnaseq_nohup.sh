#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Start the full RNA-seq pipeline in the background with nohup.
#
# This runs:
#   01_qc_trim.sh
#   02_align_sort_index.sh
#   03_featurecounts.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/rnaseq_pipeline.nohup.log"

nohup "$SCRIPT_DIR/run_all_rnaseq.sh" > "$LOG_FILE" 2>&1 &
PID=$!

echo "Started full RNA-seq pipeline in the background."
echo "PID: $PID"
echo "Log file: $LOG_FILE"
echo "Check progress with: tail -f \"$LOG_FILE\""
