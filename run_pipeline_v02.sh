#!/bin/bash

set -e  # Stop on first error

# Check for -s flag
SKIP_PREPROCESSING=false
for arg in "$@"; do
  if [[ "$arg" == "-s" ]]; then
    SKIP_PREPROCESSING=true
    break
  fi
done

# Remove the flag from the arguments array for easier parsing
ARGS=()
for arg in "$@"; do
  if [[ "$arg" != "-s" ]]; then
    ARGS+=("$arg")
  fi
done

# Validation
if [[ "$SKIP_PREPROCESSING" == "true" && "${#ARGS[@]}" -ne 4 ]]; then
  echo "Usage (skipping preprocessing): $0 <GENOMEINFO.csv> <PARAMETERS.csv> <DATAINFO.csv> <SPECIES> -s"
  exit 1
elif [[ "$SKIP_PREPROCESSING" == "false" && ("${#ARGS[@]}" -lt 7 || "$#" -gt 8 ) ]]; then
  echo "Usage (with preprocessing): $0 <PATHTODATA> <DATA_SUBDIR> <ADAPTERFILE> <GENOMEINDEX> <GENOMEINFO.csv> <PARAMETERS.csv> <SPECIES> [-s]"
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

set -e  # Stop on first error

# Run preprocessing if not skipped
if [[ "$SKIP_PREPROCESSING" == "false" ]]; then
  echo "========================================"
  echo "Running preprocessing script..."
  echo "Input: $PATHTODATA $DATA_SUBDIR $ADAPTERFILE"
  echo "========================================"

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

# Run Java analysis
echo "========================================"
echo "Running Java analysis..."
echo "Input: $GENOMEINFO $PARAMETERS [$DATAINFO] $SPECIES"
echo "========================================"

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


if [[ -n "$DATAINFO" && -n "$DATAFILE" ]]; then
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_14.jar \
    "/jcna/input/$GENOMEINFOFILE" \
    "/jcna/input/$PARAMETERSFILE" \
    "/jcna/input/$DATAFILE" \
    "$SPECIES"
else
  java -jar -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml \
    /home/avo/jars/jcna-kldiv_14.jar \
    "/jcna/input/$GENOMEINFOFILE" \
    "/jcna/input/$PARAMETERSFILE" \
    "$SPECIES"
fi
