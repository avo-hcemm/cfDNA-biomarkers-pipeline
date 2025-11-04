#!/bin/bash

# Validation
if [[ "$#" -lt 7 || "$#" -gt 8 ]]; then
  echo "Usage: $0 <PATHTODATA> <DATA_SUBDIR> <PATHTOADAPTERFILE> <GENOMEINDEX> <GENOMEINFO.csv> <PARAMETERS.csv> [DATAINFO.csv] <SPECIES>"
  exit 1
fi

# Arguments
PATHTODATA=$1
DATA_SUBDIR=$2
ADAPTERFILE=$3
GENOMEINDEX=$4
GENOMEINFO=$5
PARAMETERS=$6

if [[ "$#" -eq 8 ]]; then
  DATAINFO=$7
  SPECIES=$8
else
  DATAINFO=""
  SPECIES=$7
fi

# Default max heap size if not provided
HEAP_SIZE=${JAVA_HEAP:-32g}

set -e  # Stop on first error

echo "========================================"
echo "Running preprocessing script..."
echo "Input: $PATHTODATA $DATA_SUBDIR $ADAPTERFILE"
echo "========================================"

bash scripts/reads_preprocessing.sh \
"$PATHTODATA" \
"$DATA_SUBDIR" \
"$ADAPTERFILE"	\
"$GENOMEINDEX"

echo "========================================"
echo "Running Java analysis..."
echo "Input: $GENOMEINFO $PARAMETERS [$DATAINFO] $SPECIES"
echo "========================================"

GENOMEINFOFILE=$(basename "$GENOMEINFO")
PARAMETERSFILE=$(basename "$PARAMETERS")
cp "$GENOMEINFO" "jcna/input/"
cp "$PARAMETERS" "jcna/input/"

if [[ -n "$DATAINFO" && -f "$DATAINFO" ]]; then
  DATAFILE=$(basename "$DATAINFO")
  cp "$DATAINFO" "jcna/input/"
fi
	
echo "Files in input folder:"
ls jcna/input/


if [[ -n "$DATAINFO" && -n "$DATAFILE" ]]; then
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_14.jar \
    "jcna/input/$GENOMEINFOFILE" \
    "jcna/input/$PARAMETERSFILE" \
    "jcna/input/$DATAFILE" \
    "$SPECIES"
else
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_14.jar \
    "jcna/input/$GENOMEINFOFILE" \
    "jcna/input/$PARAMETERSFILE" \
    "$SPECIES"
fi



