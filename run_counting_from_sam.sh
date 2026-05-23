#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/convert_and_index_bams.sh"
"$SCRIPT_DIR/03_featurecounts.sh"

echo "SAM-to-BAM conversion and featureCounts are complete."
