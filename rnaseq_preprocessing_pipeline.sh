#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# RNA-seq preprocessing pipeline
#
# Typical flow:
#   1. Run FastQC on raw FASTQ files.
#   2. Trim adapters / low-quality bases with fastp.
#   3. Run FastQC again on trimmed FASTQ files.
#   4. Summarize QC with MultiQC.
#   5. Align trimmed reads with HISAT2.
#   6. Convert SAM to sorted BAM and index BAM files.
#   7. Count reads with featureCounts.
#
# Edit the paths in the "User settings" section before running.
###############################################################################

#################
# User settings #
#################

# Directory containing raw paired-end FASTQ files.
RAW_DIR="/data/home/fengl/Roseli/RNAseq_files/raw_fastq"

# Output directory for the full preprocessing run.
OUT_DIR="/data/home/fengl/Roseli/RNAseq_files/preprocessing_output"

# HISAT2 genome index prefix, not a directory.
# Example: /data/home/fengl/genome_index/hisat2/mm10/genome
HISAT2_INDEX="/data/home/fengl/Roseli/RNAseq_files/reference/hisat2_index/genome"

# Gene annotation file for featureCounts.
# Example: /data/home/fengl/reference/Mus_musculus.GRCm39.110.gtf
GTF_FILE="/data/home/fengl/Roseli/RNAseq_files/reference/genes.gtf"

# Number of CPU threads to use.
THREADS=8

# Paired-end FASTQ filename pattern.
# This script expects names like:
#   sample_1.fastq.gz and sample_2.fastq.gz
# or:
#   sample_R1.fastq.gz and sample_R2.fastq.gz
READ1_SUFFIX="_1.fastq.gz"
READ2_SUFFIX="_2.fastq.gz"

#####################
# Derived locations #
#####################

RAW_QC_DIR="$OUT_DIR/01_fastqc_raw"
TRIM_DIR="$OUT_DIR/02_trimmed_fastq"
TRIM_QC_DIR="$OUT_DIR/03_fastqc_trimmed"
MULTIQC_DIR="$OUT_DIR/04_multiqc"
SAM_DIR="$OUT_DIR/05_sam"
BAM_DIR="$OUT_DIR/06_sorted_bam"
COUNTS_DIR="$OUT_DIR/07_featurecounts"
LOG_DIR="$OUT_DIR/logs"

####################
# Helper functions #
####################

check_command() {
    local cmd="$1"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command not found: $cmd" >&2
        exit 1
    fi
}

sample_name_from_read1() {
    local read1_file="$1"
    local file_name

    file_name="$(basename "$read1_file")"
    echo "${file_name%"$READ1_SUFFIX"}"
}

################
# Main script  #
################

check_command fastqc
check_command multiqc
check_command fastp
check_command hisat2
check_command samtools
check_command featureCounts

mkdir -p \
    "$RAW_QC_DIR" \
    "$TRIM_DIR" \
    "$TRIM_QC_DIR" \
    "$MULTIQC_DIR" \
    "$SAM_DIR" \
    "$BAM_DIR" \
    "$COUNTS_DIR" \
    "$LOG_DIR"

echo "Step 1: FastQC on raw FASTQ files"
fastqc -t "$THREADS" -o "$RAW_QC_DIR" "$RAW_DIR"/*.fastq.gz

echo "Step 2: Trim adapters and low-quality reads with fastp"
for read1 in "$RAW_DIR"/*"$READ1_SUFFIX"; do
    if [[ ! -e "$read1" ]]; then
        echo "No read 1 files found in $RAW_DIR with suffix $READ1_SUFFIX" >&2
        exit 1
    fi

    sample="$(sample_name_from_read1 "$read1")"
    read2="$RAW_DIR/${sample}${READ2_SUFFIX}"

    if [[ ! -e "$read2" ]]; then
        echo "Missing read 2 file for sample $sample: $read2" >&2
        exit 1
    fi

    fastp \
        --thread "$THREADS" \
        --in1 "$read1" \
        --in2 "$read2" \
        --out1 "$TRIM_DIR/${sample}_trimmed_R1.fastq.gz" \
        --out2 "$TRIM_DIR/${sample}_trimmed_R2.fastq.gz" \
        --html "$LOG_DIR/${sample}_fastp.html" \
        --json "$LOG_DIR/${sample}_fastp.json"
done

echo "Step 3: FastQC on trimmed FASTQ files"
fastqc -t "$THREADS" -o "$TRIM_QC_DIR" "$TRIM_DIR"/*.fastq.gz

echo "Step 4: MultiQC summary"
multiqc "$OUT_DIR" -o "$MULTIQC_DIR"

echo "Step 5: Align trimmed reads with HISAT2"
for read1 in "$TRIM_DIR"/*_trimmed_R1.fastq.gz; do
    if [[ ! -e "$read1" ]]; then
        echo "No trimmed read 1 files found in $TRIM_DIR" >&2
        exit 1
    fi

    sample="$(basename "$read1" _trimmed_R1.fastq.gz)"
    read2="$TRIM_DIR/${sample}_trimmed_R2.fastq.gz"
    sam_file="$SAM_DIR/${sample}.sam"

    hisat2 \
        -p "$THREADS" \
        -x "$HISAT2_INDEX" \
        -1 "$read1" \
        -2 "$read2" \
        -S "$sam_file" \
        2> "$LOG_DIR/${sample}_hisat2.log"
done

echo "Step 6: Convert SAM to sorted BAM and index"
for sam_file in "$SAM_DIR"/*.sam; do
    if [[ ! -e "$sam_file" ]]; then
        echo "No SAM files found in $SAM_DIR" >&2
        exit 1
    fi

    sample="$(basename "$sam_file" .sam)"
    sorted_bam="$BAM_DIR/${sample}.sorted.bam"

    samtools view -@ "$THREADS" -bS "$sam_file" | \
        samtools sort -@ "$THREADS" -o "$sorted_bam"
    samtools index "$sorted_bam"
done

echo "Step 7: Count reads with featureCounts"
featureCounts \
    -T "$THREADS" \
    -p \
    -s 0 \
    -a "$GTF_FILE" \
    -o "$COUNTS_DIR/gene_counts.txt" \
    "$BAM_DIR"/*.sorted.bam \
    > "$LOG_DIR/featureCounts.log" 2>&1

echo "RNA-seq preprocessing pipeline complete."
echo "Main count table: $COUNTS_DIR/gene_counts.txt"
echo "QC report: $MULTIQC_DIR/multiqc_report.html"
