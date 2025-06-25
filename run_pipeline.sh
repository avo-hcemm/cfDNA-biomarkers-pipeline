#!/bin/bash

# Arguments
PATHTODATA=$1
DATA_SUBDIR=$2
ADAPTERFILE=$3
GENOMEINFO=$4
DATAINFO=$5
PARAMETERS=$6
SPECIES=$7

# Validation
if [[ $# -ne 7 ]]; then
  echo "Usage: $0 <PATHTODATA> <DATA_SUBDIR> <ADAPTERFILE> <GENOMEINFO.csv> <DATAINFO.csv> <PARAMETERS.csv> <SPECIES>"
  exit 1
fi

# Default max heap size if not provided
HEAP_SIZE=${JAVA_HEAP:-32g}

set -e  # Stop on first error

echo "========================================"
echo "Running preprocessing script..."
echo "Input: $PATHTODATA $DATA_SUBDIR $ADAPTERFILE"
echo "========================================"

bash /app/sequencing/bash_scripts/reads_prep_NCBI_H_filtered_max600_test.sh \
"$PATHTODATA" \
"$DATA_SUBDIR" \
"$ADAPTERFILE"

echo "========================================"
echo "Running Java analysis..."
echo "Input: $GENOMEINFO $DATAINFO $PARAMETERS ($SPECIES)"
echo "========================================"

java -jar -Xmx"$HEAP_SIZE" /app/jcna-kldiv_11.4.jar \
    "$GENOMEINFO" \
    "$DATAINFO" \
    "$PARAMETERS" \
    "$SPECIES"
