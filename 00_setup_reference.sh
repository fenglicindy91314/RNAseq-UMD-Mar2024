#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Optional reference setup helper
#
# Run this only if the mouse HISAT2 index or GTF annotation file are not already
# installed on the server.
###############################################################################

source "$(dirname "$0")/rnaseq_config.sh"

MM10_DIR="/data/home/lfeng1/mm10"
GTF_DIR="/data/home/lfeng1/GTF"

mkdir -p "$MM10_DIR" "$GTF_DIR"

echo "Downloading HISAT2 mm10 genome index..."
cd "$MM10_DIR"
if [[ ! -f mm10_genome.tar.gz ]]; then
    wget https://genome-idx.s3.amazonaws.com/hisat/mm10_genome.tar.gz
fi

if [[ ! -d mm10 ]]; then
    tar -xzvf mm10_genome.tar.gz
fi

echo "Downloading GENCODE mouse M10 GTF..."
cd "$GTF_DIR"
if [[ ! -f gencode.vM10.annotation.gtf ]]; then
    if [[ ! -f gencode.vM10.annotation.gtf.gz ]]; then
        wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M10/gencode.vM10.annotation.gtf.gz
    fi
    gunzip -k gencode.vM10.annotation.gtf.gz
fi

echo "Reference setup complete."
echo "HISAT2 index prefix should be: $HISAT2_INDEX"
echo "GTF file should be: $GTF_FILE"
