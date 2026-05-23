#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Step 1: QC and trimming
#
# Runs FastQC on raw reads. If TRIM_READS=true in rnaseq_config.sh, trims paired
# raw FASTQ files with fastp and then runs FastQC on trimmed reads.
###############################################################################

source "$(dirname "$0")/rnaseq_config.sh"

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command not found: $cmd" >&2
        exit 1
    fi
}

sample_from_raw_r1() {
    local read1_file="$1"
    local file_name
    file_name="$(basename "$read1_file")"
    echo "${file_name%"$RAW_R1_SUFFIX"}"
}

check_command fastqc
mkdir -p "$QC_DIR/raw_fastqc" "$QC_DIR/trimmed_fastqc" "$TRIMMED_DIR" "$LOG_DIR"

echo "Running FastQC on raw FASTQ files..."
fastqc -t "$THREADS" -o "$QC_DIR/raw_fastqc" "$RAW_DIR"/*.fastq.gz

if [[ "$TRIM_READS" == "true" ]]; then
    check_command fastp

    echo "Trimming paired-end reads with fastp..."
    for read1 in "$RAW_DIR"/*"$RAW_R1_SUFFIX"; do
        if [[ ! -e "$read1" ]]; then
            echo "No raw R1 files found in $RAW_DIR with suffix $RAW_R1_SUFFIX" >&2
            exit 1
        fi

        sample="$(sample_from_raw_r1 "$read1")"
        read2="$RAW_DIR/${sample}${RAW_R2_SUFFIX}"

        if [[ ! -e "$read2" ]]; then
            echo "Missing raw R2 file for sample $sample: $read2" >&2
            exit 1
        fi

        echo "Trimming sample: $sample"
        fastp \
            --thread "$THREADS" \
            --in1 "$read1" \
            --in2 "$read2" \
            --out1 "$TRIMMED_DIR/${sample}${TRIMMED_R1_SUFFIX}" \
            --out2 "$TRIMMED_DIR/${sample}${TRIMMED_R2_SUFFIX}" \
            --html "$LOG_DIR/${sample}_fastp.html" \
            --json "$LOG_DIR/${sample}_fastp.json"
    done
else
    echo "TRIM_READS=false, skipping trimming."
fi

echo "Running FastQC on trimmed FASTQ files..."
fastqc -t "$THREADS" -o "$QC_DIR/trimmed_fastqc" "$TRIMMED_DIR"/*"$TRIMMED_R1_SUFFIX" "$TRIMMED_DIR"/*"$TRIMMED_R2_SUFFIX"

if command -v multiqc >/dev/null 2>&1; then
    echo "Running MultiQC..."
    mkdir -p "$QC_DIR/multiqc"
    multiqc "$QC_DIR" "$LOG_DIR" -o "$QC_DIR/multiqc"
else
    echo "multiqc not found; skipping MultiQC summary."
fi

echo "QC and trimming step complete."
