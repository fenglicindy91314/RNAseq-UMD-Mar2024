#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Convert existing SAM files to sorted/indexed BAM files.
#
# This is a small helper for the counting workflow from the original notes. For
# the full reusable pipeline, use 02_align_sort_index.sh or run_all_rnaseq.sh.
###############################################################################

source "$(dirname "$0")/rnaseq_config.sh"

mkdir -p "$BAM_DIR"

for sam_file in "$ALIGN_DIR"/*"$SAM_SUFFIX"; do
    if [[ ! -e "$sam_file" ]]; then
        echo "No SAM files found in $ALIGN_DIR with suffix $SAM_SUFFIX" >&2
        exit 1
    fi

    base_name="$(basename "$sam_file" .sam)"
    sorted_bam="$BAM_DIR/${base_name}.sorted.bam"

    echo "Converting and sorting: $sam_file"
    samtools view -@ "$THREADS" -bS "$sam_file" | \
        samtools sort -@ "$THREADS" -o "$sorted_bam"

    echo "Indexing: $sorted_bam"
    samtools index "$sorted_bam"
done

echo "Conversion and indexing complete."
