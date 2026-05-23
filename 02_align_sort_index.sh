#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Step 2: Alignment, SAM to sorted BAM, and BAM indexing
#
# Aligns paired trimmed FASTQ files with HISAT2, writes SAM files matching the
# original project convention, then converts each SAM to sorted/indexed BAM.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rnaseq_config.sh"

# Make unmatched file patterns expand to an empty list instead of a literal
# string like "*.sam".
shopt -s nullglob

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

# HISAT2 expects an index prefix, such as ".../genome"; the actual files end in
# .ht2 or .ht2l. This catches a wrong path before alignment starts.
if ! compgen -G "${HISAT2_INDEX}*.ht2" >/dev/null && ! compgen -G "${HISAT2_INDEX}*.ht2l" >/dev/null; then
    echo "No HISAT2 index files found for prefix: $HISAT2_INDEX" >&2
    exit 1
fi

trimmed_r1_files=("$TRIMMED_DIR"/*"$TRIMMED_R1_SUFFIX")
# Stop early if the configured trimmed FASTQ suffix does not match the files.
if (( ${#trimmed_r1_files[@]} == 0 )); then
    echo "No trimmed R1 files found in $TRIMMED_DIR with suffix $TRIMMED_R1_SUFFIX" >&2
    exit 1
fi

echo "Aligning trimmed reads with HISAT2..."
for read1 in "${trimmed_r1_files[@]}"; do
    sample="$(sample_from_trimmed_r1 "$read1")"
    read2="$TRIMMED_DIR/${sample}${TRIMMED_R2_SUFFIX}"
    sam_file="$ALIGN_DIR/${sample}${SAM_SUFFIX}"

    # HISAT2 needs both mates for paired-end alignment.
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

sam_files=("$ALIGN_DIR"/*"$SAM_SUFFIX")
# If HISAT2 failed or wrote files with a different suffix, do not continue into
# samtools with an empty input set.
if (( ${#sam_files[@]} == 0 )); then
    echo "No SAM files found in $ALIGN_DIR with suffix $SAM_SUFFIX" >&2
    exit 1
fi

echo "Converting SAM files to sorted BAM files and indexing..."
for sam_file in "${sam_files[@]}"; do
    base_name="$(basename "$sam_file" .sam)"
    sorted_bam="$BAM_DIR/${base_name}.sorted.bam"

    echo "Sorting BAM for: $base_name"
    samtools view -@ "$THREADS" -bS "$sam_file" | \
        samtools sort -@ "$THREADS" -o "$sorted_bam"

    samtools index "$sorted_bam"
done

echo "Alignment, sorting, and indexing step complete."
