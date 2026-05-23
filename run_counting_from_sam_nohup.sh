#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Start SAM-to-counts processing in the background with nohup.
#
# This runs:
#   convert_and_index_bams.sh
#   03_featurecounts.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/counting_from_sam.nohup.log"

nohup "$SCRIPT_DIR/run_counting_from_sam.sh" > "$LOG_FILE" 2>&1 &
PID=$!

echo "Started SAM-to-counts processing in the background."
echo "PID: $PID"
echo "Log file: $LOG_FILE"
echo "Check progress with: tail -f \"$LOG_FILE\""
