#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Step 3: Gene-level read counting with featureCounts
###############################################################################

source "$(dirname "$0")/rnaseq_config.sh"

if ! command -v featureCounts >/dev/null 2>&1; then
    echo "Error: required command not found: featureCounts" >&2
    exit 1
fi

mkdir -p "$COUNT_DIR" "$LOG_DIR"

echo "Counting reads with featureCounts..."
featureCounts \
    -a "$GTF_FILE" \
    -o "$FEATURECOUNTS_OUTPUT" \
    -T "$THREADS" \
    -p \
    -s "$FEATURECOUNTS_STRAND" \
    "$BAM_DIR"/*.sorted.bam \
    > "$LOG_DIR/featureCounts.log" 2>&1

echo "featureCounts complete."
echo "Count table: $FEATURECOUNTS_OUTPUT"
echo "Summary: ${FEATURECOUNTS_OUTPUT}.summary"
