#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Step 3: Gene-level read counting with featureCounts
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rnaseq_config.sh"

# Make unmatched BAM patterns expand to an empty list instead of a literal
# string like "*.sorted.bam".
shopt -s nullglob

if ! command -v featureCounts >/dev/null 2>&1; then
    echo "Error: required command not found: featureCounts" >&2
    exit 1
fi

mkdir -p "$COUNT_DIR" "$LOG_DIR"

# featureCounts cannot start without the gene annotation file.
if [[ ! -f "$GTF_FILE" ]]; then
    echo "GTF annotation file not found: $GTF_FILE" >&2
    exit 1
fi

bam_files=("$BAM_DIR"/*.sorted.bam)
# Stop early if the previous SAM-to-BAM step has not produced sorted BAM files.
if (( ${#bam_files[@]} == 0 )); then
    echo "No sorted BAM files found in $BAM_DIR" >&2
    exit 1
fi

echo "Counting reads with featureCounts..."
featureCounts \
    -a "$GTF_FILE" \
    -o "$FEATURECOUNTS_OUTPUT" \
    -T "$THREADS" \
    -p \
    -s "$FEATURECOUNTS_STRAND" \
    "${bam_files[@]}" \
    > "$LOG_DIR/featureCounts.log" 2>&1

echo "featureCounts complete."
echo "Count table: $FEATURECOUNTS_OUTPUT"
echo "Summary: ${FEATURECOUNTS_OUTPUT}.summary"
