#!/usr/bin/env bash
set -euo pipefail

# Directory containing SAM files.
sam_dir="/data/home/fengl/Roseli/RNAseq_files/LIR_02_SOL"

# Directory to store sorted BAM files.
bam_dir="/data/home/fengl/Roseli/RNAseq_files/counts/sorted_bams2"

mkdir -p "$bam_dir"

# Convert each *2.sam file to a sorted BAM file, then index it.
for sam_file in "$sam_dir"/*2.sam; do
    if [[ ! -e "$sam_file" ]]; then
        echo "No *2.sam files found in: $sam_dir" >&2
        exit 1
    fi

    base_name="$(basename "$sam_file" .sam)"
    sorted_bam="$bam_dir/${base_name}.sorted.bam"

    echo "Converting and sorting: $sam_file"
    samtools view -bS "$sam_file" | samtools sort -o "$sorted_bam"

    echo "Indexing: $sorted_bam"
    samtools index "$sorted_bam"
done

echo "Conversion and indexing complete."
