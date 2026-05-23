#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Step 2: Alignment, SAM to sorted BAM, and BAM indexing
#
# Aligns paired trimmed FASTQ files with HISAT2, writes SAM files matching the
# original project convention, then converts each SAM to sorted/indexed BAM.
###############################################################################

source "$(dirname "$0")/rnaseq_config.sh"

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command not found: $cmd" >&2
        exit 1
    fi
}

sample_from_trimmed_r1() {
    local read1_file="$1"
    local file_name
    file_name="$(basename "$read1_file")"
    echo "${file_name%"$TRIMMED_R1_SUFFIX"}"
}

check_command hisat2
check_command samtools

mkdir -p "$ALIGN_DIR" "$BAM_DIR" "$LOG_DIR"

echo "Aligning trimmed reads with HISAT2..."
for read1 in "$TRIMMED_DIR"/*"$TRIMMED_R1_SUFFIX"; do
    if [[ ! -e "$read1" ]]; then
        echo "No trimmed R1 files found in $TRIMMED_DIR with suffix $TRIMMED_R1_SUFFIX" >&2
        exit 1
    fi

    sample="$(sample_from_trimmed_r1 "$read1")"
    read2="$TRIMMED_DIR/${sample}${TRIMMED_R2_SUFFIX}"
    sam_file="$ALIGN_DIR/${sample}${SAM_SUFFIX}"

    if [[ ! -e "$read2" ]]; then
        echo "Missing trimmed R2 file for sample $sample: $read2" >&2
        exit 1
    fi

    echo "Aligning sample: $sample"
    hisat2 \
        -p "$THREADS" \
        -x "$HISAT2_INDEX" \
        -1 "$read1" \
        -2 "$read2" \
        -S "$sam_file" \
        2> "$LOG_DIR/${sample}_hisat2.log"
done

echo "Converting SAM files to sorted BAM files and indexing..."
for sam_file in "$ALIGN_DIR"/*"$SAM_SUFFIX"; do
    if [[ ! -e "$sam_file" ]]; then
        echo "No SAM files found in $ALIGN_DIR with suffix $SAM_SUFFIX" >&2
        exit 1
    fi

    base_name="$(basename "$sam_file" .sam)"
    sorted_bam="$BAM_DIR/${base_name}.sorted.bam"

    echo "Sorting BAM for: $base_name"
    samtools view -@ "$THREADS" -bS "$sam_file" | \
        samtools sort -@ "$THREADS" -o "$sorted_bam"

    samtools index "$sorted_bam"
done

echo "Alignment, sorting, and indexing step complete."
