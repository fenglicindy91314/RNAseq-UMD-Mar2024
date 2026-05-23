#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Run all RNA-seq preprocessing steps.
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/01_qc_trim.sh"
"$SCRIPT_DIR/02_align_sort_index.sh"
"$SCRIPT_DIR/03_featurecounts.sh"

echo "Full RNA-seq preprocessing pipeline complete."
