#!/bin/bash

set -euo pipefail

# Default values
CHROMOSOME_JOB=false
CHR=""
OUTPUTDIR=""
INPUTDIR=""

# Parse flags and remove them from arguments
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i)
  	  INPUTDIR="$2"
  	  shift 2
  	  ;;  
  	-o)
  	  OUTPUTDIR="$2"
  	  shift 2
  	  ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Validation of args length
if [[ "${#ARGS[@]}" -lt 4 ]]; then
  echo "Usage (with preprocessing): $0 <PATHTODATA> <DATA_SUBDIR> <ADAPTERFILE> <GENOMEINDEX> -i <INPUTDIR> -o <OUTPUTDIR>"
  exit 1
fi

PATHTODATA=${ARGS[0]}
DATA_SUBDIR=${ARGS[1]}
ADAPTERFILE=${ARGS[2]}
GENOMEINDEX=${ARGS[3]}


# Run preprocessing if not skipped
echo "==============================================="
echo "Running preprocessing script..."
echo "Input: $PATHTODATA $DATA_SUBDIR $ADAPTERFILE"
echo "==============================================="

echo "$INPUTDIR"/scripts/reads_preprocessing.sh 

bash "$INPUTDIR"/scripts/reads_preprocessing.sh \
  "$PATHTODATA" \
  "$DATA_SUBDIR" \
  "$ADAPTERFILE" \
  "$GENOMEINDEX" \
  -o "$OUTPUTDIR"
