#!/usr/bin/env bash

###############################################################################
# RNA-seq pipeline configuration
#
# Edit this file before running the pipeline on the server.
###############################################################################

# Project folder on the Linux server.
PROJECT_DIR="/data/home/lfeng1/RoseLi/RNAseq_files"

# Folder containing raw FASTQ files.
RAW_DIR="$PROJECT_DIR/raw_fastq"

# Folder containing trimmed FASTQ files.
# If TRIM_READS=false, this folder must already contain paired files named like:
#   C1_S58_L004_R1_001_trimmed.fastq.gz
#   C1_S58_L004_R2_001_trimmed.fastq.gz
TRIMMED_DIR="$PROJECT_DIR/LiR_02_SOL"

# Main output folders.
QC_DIR="$PROJECT_DIR/qc"
ALIGN_DIR="$PROJECT_DIR/LiR_02_SOL"
BAM_DIR="$PROJECT_DIR/counts/sorted_bams2"
COUNT_DIR="$PROJECT_DIR/counts/count_result"
LOG_DIR="$PROJECT_DIR/logs"

# HISAT2 genome index prefix. This is the prefix ending in "genome", not only
# the directory containing the index.
HISAT2_INDEX="/data/home/lfeng1/mm10/mm10/genome"

# Alternative index path seen in the older alignment notes:
# HISAT2_INDEX="/data/home/lfeng1/GRCm38/grcm38/genome"

# Gene annotation file for featureCounts.
GTF_FILE="/data/home/lfeng1/GTF/gencode.vM10.annotation.gtf"

# Number of CPU threads.
THREADS=4

# If true, run trimming from RAW_DIR into TRIMMED_DIR using fastp.
# If false, skip trimming and use existing files in TRIMMED_DIR.
TRIM_READS=true

# Raw FASTQ filename pattern used when TRIM_READS=true.
RAW_R1_SUFFIX="_R1_001.fastq.gz"
RAW_R2_SUFFIX="_R2_001.fastq.gz"

# Trimmed FASTQ filename pattern used for alignment.
TRIMMED_R1_SUFFIX="_R1_001_trimmed.fastq.gz"
TRIMMED_R2_SUFFIX="_R2_001_trimmed.fastq.gz"

# HISAT2 output suffix. Your notes used files such as C1_S58_L004_002.sam.
SAM_SUFFIX="_002.sam"

# featureCounts settings.
# -p means paired-end.
# The original notes used paired-end mode without a stranded flag.
# Change FEATURECOUNTS_STRAND to 1 or 2 if your library is stranded.
FEATURECOUNTS_STRAND=0
FEATURECOUNTS_OUTPUT="$COUNT_DIR/combined_feature_counts.txt"
