#!/bin/bash

set -e  # Stop on first error

# Default values
SKIP_PREPROCESSING=false
CHROMOSOME_JOB=false
CHR=""

# Parse flags and remove them from arguments
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s)
      SKIP_PREPROCESSING=true
      shift
      ;;
    --chromosome)
      CHROMOSOME_JOB=true
      CHR="$2"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Validation of args length depending on mode
if [[ "$SKIP_PREPROCESSING" == "true" && "${#ARGS[@]}" -lt 4 ]]; then
  echo "Usage (skipping preprocessing): $0 <GENOMEINFO.csv> <PARAMETERS.csv> <DATAINFO.csv> <SPECIES> -s --chromosome [CHR]"
  exit 1
elif [[ "$SKIP_PREPROCESSING" == "false" && ("${#ARGS[@]}" -lt 7 || "${#ARGS[@]}" -gt 8) ]]; then
  echo "Usage (with preprocessing): $0 <PATHTODATA> <DATA_SUBDIR> <ADAPTERFILE> <GENOMEINDEX> <GENOMEINFO.csv> <PARAMETERS.csv> [DATAINFO.csv] <SPECIES> [-s] --chromosome [CHR]"
  exit 1
fi

# Assign arguments based on mode
if [[ "$SKIP_PREPROCESSING" == "true" ]]; then
  GENOMEINFO=${ARGS[0]}
  PARAMETERS=${ARGS[1]}
  DATAINFO=${ARGS[2]}
  SPECIES=${ARGS[3]}
else
  PATHTODATA=${ARGS[0]}
  DATA_SUBDIR=${ARGS[1]}
  ADAPTERFILE=${ARGS[2]}
  GENOMEINDEX=${ARGS[3]}
  GENOMEINFO=${ARGS[4]}
  PARAMETERS=${ARGS[5]}
  if [[ "${#ARGS[@]}" -eq 8 ]]; then
    DATAINFO=${ARGS[6]}
    SPECIES=${ARGS[7]}
  else
    DATAINFO=""
    SPECIES=${ARGS[6]}
  fi
fi

# Default max heap size if not provided
HEAP_SIZE=${JAVA_HEAP:-32g}

# Run preprocessing if not skipped
if [[ "$SKIP_PREPROCESSING" == "false" ]]; then
  echo "==============================================="
  echo "Running preprocessing script..."
  echo "Input: $PATHTODATA $DATA_SUBDIR $ADAPTERFILE"
  echo "==============================================="

  bash scripts/reads_preprocessing.sh \
    "$PATHTODATA" \
    "$DATA_SUBDIR" \
    "$ADAPTERFILE" \
    "$GENOMEINDEX"

  # Define DATAINFO from preprocessing output (assumption: fixed path or naming convention)
  DATAINFO="$PATHTODATA/$DATA_SUBDIR/DATAINFO.csv"
else
  echo "========================================"
  echo "Skipping preprocessing step."
  echo "========================================"
fi

# Copy input files
GENOMEINFOFILE=$(basename "$GENOMEINFO")
PARAMETERSFILE=$(basename "$PARAMETERS")
cp "$GENOMEINFO" "/jcna/input/$GENOMEINFOFILE"
cp "$PARAMETERS" "/jcna/input/$PARAMETERSFILE"

if [[ -n "$DATAINFO" && -f "$DATAINFO" ]]; then
  DATAFILE=$(basename "$DATAINFO")
  cp "$DATAINFO" "/jcna/input/$DATAFILE"
fi

echo "Files in input folder:"
ls /jcna/input/

# Run Java analysis with or without chromosome and DATAINFO
if [[ -n "$DATAINFO" && -n "$DATAFILE" && "$CHROMOSOME_JOB" == "true" ]]; then
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_15.jar \
    "/jcna/input/$GENOMEINFOFILE" \
    "/jcna/input/$PARAMETERSFILE" \
    "/jcna/input/$DATAFILE" \
    "$SPECIES" \
    --chromosome "$CHR"
elif [[ "$CHROMOSOME_JOB" == "true" ]]; then
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_15.jar \
    "/jcna/input/$GENOMEINFOFILE" \
    "/jcna/input/$PARAMETERSFILE" \
    "$SPECIES" \
    --chromosome "$CHR"
else
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_15.jar \
    "/jcna/input/$GENOMEINFOFILE" \
    "/jcna/input/$PARAMETERSFILE" \
    "$SPECIES"
fi
