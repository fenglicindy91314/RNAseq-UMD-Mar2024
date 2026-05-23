#!/usr/bin/env bash
set -euo pipefail

./convert_and_index_bams.sh

# Step 2 from the screenshot: run featureCounts in the background and log output.
nohup ./run_featurecounts2.sh > output2.log 2>&1 &

echo "featureCounts started in the background. Log: output2.log"
