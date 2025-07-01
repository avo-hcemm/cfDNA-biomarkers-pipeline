#!/bin/bash

# Validation
if [[ "$#" -lt 6 || "$#" -gt 7 ]]; then
  echo "Usage: $0 <PATHTODATA> <DATA_SUBDIR> <PATHTOADAPTERFILE> <GENOMEINFO.csv> <PARAMETERS.csv> [DATAINFO.csv] <SPECIES>"
  exit 1
fi

# Arguments
PATHTODATA=$1
DATA_SUBDIR=$2
ADAPTERFILE=$3
GENOMEINFO=$4
PARAMETERS=$5

if [[ "$#" -eq 7 ]]; then
  DATAINFO=$6
  SPECIES=$7
else
  DATAINFO=""
  SPECIES=$6
fi

# Default max heap size if not provided
HEAP_SIZE=${JAVA_HEAP:-32g}

set -e  # Stop on first error

echo "========================================"
echo "Running preprocessing script..."
echo "Input: $PATHTODATA $DATA_SUBDIR $ADAPTERFILE"
echo "========================================"

bash /app/sequencing/bash_scripts/reads_preprocessing.sh \
"$PATHTODATA" \
"$DATA_SUBDIR" \
"$ADAPTERFILE"

echo "========================================"
echo "Running Java analysis..."
echo "Input: $GENOMEINFO $PARAMETERS [$DATAINFO] $SPECIES"
echo "========================================"

if [[ "$#" -eq 7 ]]; then
  java -jar -Xmx"$HEAP_SIZE" /app/jcna-kldiv_13.jar \
    "$GENOMEINFO" \
    "$PARAMETERS" \
    "$DATAINFO" \
    "$SPECIES"
else
  java -jar -Xmx"$HEAP_SIZE" /app/jcna-kldiv_13.jar \
    "$GENOMEINFO" \
    "$PARAMETERS" \
    "$SPECIES"
fi


