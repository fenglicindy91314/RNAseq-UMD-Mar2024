# Reusable RNA-seq Preprocessing Pipeline

This folder contains reusable Bash scripts for preprocessing paired-end mouse RNA-seq data. The scripts are based on the Word documents you provided for the Rose Li RNA-seq project.

The original notes used paths such as:

```bash
/data/home/lfeng1/RoseLi/RNAseq_files
/data/home/lfeng1/mm10/mm10/genome
/data/home/lfeng1/GTF/gencode.vM10.annotation.gtf
```

Those are Linux server paths, so the scripts should be run on the server or cluster where the data and tools are installed.

## Files

| File | Purpose |
| --- | --- |
| `rnaseq_config.sh` | Main editable configuration file for paths, filename suffixes, threads, HISAT2 index, and GTF annotation. |
| `00_setup_reference.sh` | Optional helper to download the HISAT2 mm10 index and GENCODE mouse M10 GTF file. |
| `01_qc_trim.sh` | Runs FastQC on raw reads, optionally trims reads with fastp, runs FastQC on trimmed reads, and runs MultiQC if available. |
| `02_align_sort_index.sh` | Aligns trimmed paired-end FASTQ files with HISAT2, creates SAM files, converts them to sorted BAM files, and indexes the BAM files. |
| `03_featurecounts.sh` | Counts reads per gene with featureCounts. |
| `run_all_rnaseq.sh` | Runs QC/trimming, alignment/sorting/indexing, and featureCounts in order. |
| `convert_and_index_bams.sh` | Older small helper for converting existing SAM files to sorted BAM files. |
| `run_pipeline.sh` | Older small helper that launches the SAM-to-BAM script plus a separate featureCounts script. |

## Pipeline Steps

The full pipeline runs:

1. FastQC on raw FASTQ files.
2. Optional read trimming with `fastp`.
3. FastQC on trimmed FASTQ files.
4. Optional MultiQC summary.
5. HISAT2 alignment to mouse reference genome.
6. SAM to sorted BAM conversion with `samtools`.
7. BAM indexing with `samtools index`.
8. Gene-level counting with `featureCounts`.

## Required Software

These commands should be available on the server:

```bash
fastqc
fastp
hisat2
samtools
featureCounts
```

Optional but recommended:

```bash
multiqc
wget
gunzip
```

On a cluster, you may need to load modules first. Example module names vary by server:

```bash
module load fastqc
module load fastp
module load hisat2
module load samtools
module load subread
module load multiqc
```

## Configure Before Running

Edit [rnaseq_config.sh](/Users/fengl3/Documents/Codex/2026-05-22/covert-the-following-to-a-bash/rnaseq_config.sh) before running.

Important settings:

```bash
PROJECT_DIR="/data/home/lfeng1/RoseLi/RNAseq_files"
RAW_DIR="$PROJECT_DIR/raw_fastq"
TRIMMED_DIR="$PROJECT_DIR/LiR_02_SOL"
HISAT2_INDEX="/data/home/lfeng1/mm10/mm10/genome"
GTF_FILE="/data/home/lfeng1/GTF/gencode.vM10.annotation.gtf"
THREADS=4
TRIM_READS=true
```

The Word documents showed trimmed files named like:

```bash
C1_S58_L004_R1_001_trimmed.fastq.gz
C1_S58_L004_R2_001_trimmed.fastq.gz
```

Those are controlled by:

```bash
TRIMMED_R1_SUFFIX="_R1_001_trimmed.fastq.gz"
TRIMMED_R2_SUFFIX="_R2_001_trimmed.fastq.gz"
```

The alignment notes used SAM outputs such as:

```bash
C1_S58_L004_002.sam
```

That is controlled by:

```bash
SAM_SUFFIX="_002.sam"
```

## If Trimmed FASTQ Files Already Exist

If you already have trimmed files in `LiR_02_SOL`, set this in `rnaseq_config.sh`:

```bash
TRIM_READS=false
```

Then you can skip trimming and run:

```bash
./02_align_sort_index.sh
./03_featurecounts.sh
```

## Optional Reference Setup

Only run this if the mm10 HISAT2 index and GTF file are not already installed:

```bash
chmod +x 00_setup_reference.sh
./00_setup_reference.sh
```

The reference helper downloads:

- HISAT2 mm10 index from `https://genome-idx.s3.amazonaws.com/hisat/mm10_genome.tar.gz`
- GENCODE mouse M10 annotation from `https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M10/gencode.vM10.annotation.gtf.gz`

## Run The Full Pipeline

Make scripts executable:

```bash
chmod +x *.sh
```

Run everything:

```bash
./run_all_rnaseq.sh
```

To keep the job running after you disconnect:

```bash
nohup ./run_all_rnaseq.sh > rnaseq_pipeline.log 2>&1 &
```

Check progress:

```bash
tail -f rnaseq_pipeline.log
```

## Run One Step At A Time

QC and trimming:

```bash
./01_qc_trim.sh
```

Alignment, sorted BAM creation, and BAM indexing:

```bash
./02_align_sort_index.sh
```

Read counting:

```bash
./03_featurecounts.sh
```

## featureCounts Settings

The notes used paired-end counting with:

```bash
featureCounts -T 4 -p
```

The reusable script adds an explicit strandedness setting:

```bash
FEATURECOUNTS_STRAND=0
```

Meaning:

| Value | Meaning |
| --- | --- |
| `0` | Unstranded |
| `1` | Stranded |
| `2` | Reverse stranded |

If you do not know the library type, check the sequencing core/library prep notes before final analysis.

## Main Outputs

With the default project paths, outputs are written to:

```bash
$PROJECT_DIR/qc/raw_fastqc
$PROJECT_DIR/qc/trimmed_fastqc
$PROJECT_DIR/qc/multiqc
$PROJECT_DIR/LiR_02_SOL
$PROJECT_DIR/counts/sorted_bams2
$PROJECT_DIR/counts/count_result
$PROJECT_DIR/logs
```

The final count table is:

```bash
$PROJECT_DIR/counts/count_result/combined_feature_counts.txt
```

The featureCounts summary is:

```bash
$PROJECT_DIR/counts/count_result/combined_feature_counts.txt.summary
```

## Notes From The Provided Documents

The documents included these project-specific details:

- HISAT2 was used for alignment.
- Mouse reference index paths included both `/data/home/lfeng1/mm10/mm10/genome` and `/data/home/lfeng1/GRCm38/grcm38/genome`.
- The mm10 HISAT2 index download URL was listed as `https://genome-idx.s3.amazonaws.com/hisat/mm10_genome.tar.gz`.
- GENCODE mouse M10 annotation was listed as `gencode.vM10.annotation.gtf`.
- SAM files were converted to sorted BAM files with `samtools view -bS ... | samtools sort -o ...`.
- Sorted BAM files were indexed with `samtools index`.
- featureCounts output was previously named `combined_feature_counts2.1.txt`.

## Local vs Server

These scripts are currently stored locally on your Mac in:

```bash
/Users/fengl3/Documents/Codex/2026-05-22/covert-the-following-to-a-bash
```

The actual RNA-seq data paths in the scripts are server paths. To run on the real data, copy the scripts to the server, edit `rnaseq_config.sh`, and run them there.
