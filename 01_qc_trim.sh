#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Step 1: QC and trimming
#
# Runs FastQC on raw reads. If TRIM_READS=true in rnaseq_config.sh, trims paired
# raw FASTQ files with fastp and then runs FastQC on trimmed reads.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/rnaseq_config.sh"

# Make unmatched file patterns expand to an empty list instead of a literal
# string like "*.fastq.gz".
shopt -s nullglob

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

mkdir -p "$QC_DIR/raw_fastqc" "$QC_DIR/trimmed_fastqc" "$TRIMMED_DIR" "$LOG_DIR"

raw_fastqs=("$RAW_DIR"/*.fastq.gz)
raw_r1_files=("$RAW_DIR"/*"$RAW_R1_SUFFIX")

check_command fastqc

# Raw FastQC is useful when raw data are available. If this script is being
# used only with already-trimmed files, allow raw FastQC to be skipped.
if (( ${#raw_fastqs[@]} > 0 )); then
    echo "Running FastQC on raw FASTQ files..."
    fastqc -t "$THREADS" -o "$QC_DIR/raw_fastqc" "${raw_fastqs[@]}"
elif [[ "$TRIM_READS" == "true" ]]; then
    echo "No raw FASTQ files found in $RAW_DIR, but TRIM_READS=true." >&2
    exit 1
else
    echo "No raw FASTQ files found in $RAW_DIR; skipping raw FastQC."
fi

if [[ "$TRIM_READS" == "true" ]]; then
    check_command fastp

    # Trimming requires paired raw files. Stop before doing any work if the
    # configured R1 suffix does not match the files in RAW_DIR.
    if (( ${#raw_r1_files[@]} == 0 )); then
        echo "No raw R1 files found in $RAW_DIR with suffix $RAW_R1_SUFFIX" >&2
        exit 1
    fi

    echo "Trimming paired-end reads with fastp..."
    for read1 in "${raw_r1_files[@]}"; do
        sample="$(sample_from_raw_r1 "$read1")"
        read2="$RAW_DIR/${sample}${RAW_R2_SUFFIX}"

        # Each R1 file must have a matching R2 file with the same sample prefix.
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

trimmed_fastqs=("$TRIMMED_DIR"/*"$TRIMMED_R1_SUFFIX" "$TRIMMED_DIR"/*"$TRIMMED_R2_SUFFIX")
# Alignment depends on trimmed files, so fail here if trimming did not create
# them or if TRIM_READS=false points to the wrong folder/suffix.
if (( ${#trimmed_fastqs[@]} == 0 )); then
    echo "No trimmed FASTQ files found in $TRIMMED_DIR." >&2
    exit 1
fi

echo "Running FastQC on trimmed FASTQ files..."
fastqc -t "$THREADS" -o "$QC_DIR/trimmed_fastqc" "${trimmed_fastqs[@]}"

if command -v multiqc >/dev/null 2>&1; then
    echo "Running MultiQC..."
    mkdir -p "$QC_DIR/multiqc"
    multiqc "$QC_DIR" "$LOG_DIR" -o "$QC_DIR/multiqc"
else
    echo "multiqc not found; skipping MultiQC summary."
fi

echo "QC and trimming step complete."
