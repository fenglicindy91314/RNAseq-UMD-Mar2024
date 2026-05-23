#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Start only featureCounts in the background with nohup.
#
# Use this when sorted/indexed BAM files already exist.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/featurecounts.nohup.log"

nohup "$SCRIPT_DIR/03_featurecounts.sh" > "$LOG_FILE" 2>&1 &
PID=$!

echo "Started featureCounts in the background."
echo "PID: $PID"
echo "Log file: $LOG_FILE"
echo "Check progress with: tail -f \"$LOG_FILE\""
