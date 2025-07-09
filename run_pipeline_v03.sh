#!/bin/bash

set -euo pipefail

# Default values
SKIP_PREPROCESSING=false
CHROMOSOME_JOB=false
CHR=""
OUTPUTDIR=""
INPUTDIR=""

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

# Validation of args length depending on mode
if [[ "$SKIP_PREPROCESSING" == "true" && "${#ARGS[@]}" -lt 3 ]]; then
  echo "Usage (skipping preprocessing): $0 <GENOMEINFO.csv> <PARAMETERSINFO.csv> [DATAINFO.csv] <SPECIES> -s [--chromosome CHR] -i <INPUTDIR> -o <OUTPUTDIR>"
  exit 1
elif [[ "$SKIP_PREPROCESSING" == "false" && ("${#ARGS[@]}" -lt 7 || "${#ARGS[@]}" -gt 8) ]]; then
  echo "Usage (with preprocessing): $0 <PATHTODATA> <DATA_SUBDIR> <ADAPTERFILE> <GENOMEINDEX> <GENOMEINFO.csv> <PARAMETERSINFO.csv> [DATAINFO.csv] <SPECIES> [--chromosome CHR] -i <INPUTDIR> -o <OUTPUTDIR>"
  exit 1
fi

# Assign arguments based on mode
if [[ "$SKIP_PREPROCESSING" == "true" && "${#ARGS[@]}" -eq 4 ]]; then
  GENOMEINFO=${ARGS[0]}
  PARAMETERSINFO=${ARGS[1]}
  DATAINFO=${ARGS[2]}
  SPECIES=${ARGS[3]}
elif [[ "$SKIP_PREPROCESSING" == "true" && "${#ARGS[@]}" -eq 3 ]]; then
  GENOMEINFO=${ARGS[0]}
  PARAMETERSINFO=${ARGS[1]}
  SPECIES=${ARGS[2]}
  DATAINFO=""
else
  PATHTODATA=${ARGS[0]}
  DATA_SUBDIR=${ARGS[1]}
  ADAPTERFILE=${ARGS[2]}
  GENOMEINDEX=${ARGS[3]}
  GENOMEINFO=${ARGS[4]}
  PARAMETERSINFO=${ARGS[5]}
  if [[ "${#ARGS[@]}" -eq 8 ]]; then
    DATAINFO=${ARGS[6]}
    SPECIES=${ARGS[7]}
  else
    SPECIES=${ARGS[6]}
    DATAINFO=""
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

  bash "$INPUTDIR"/scripts/reads_preprocessing.sh \
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

echo "Running Java with arguments:"
echo "GENOMEINFO: $GENOMEINFO"
echo "PARAMETERSINFO: $PARAMETERSINFO"
echo "DATAINFO: $DATAINFO"
echo "SPECIES: $SPECIES"
[[ "$CHROMOSOME_JOB" == "true" ]] && echo "Chromosome: $CHR"

if [[ -z "$OUTPUTDIR" ]]; then
  echo "Error: OUTPUTDIR is not specified. Use -o <output_dir>"
  exit 1
fi

cd "$OUTPUTDIR" || { echo "Error: Failed to change to $OUTPUTDIR"; exit 1; }


echo "Now in: $PWD"

JAR_PATH=${JAR_PATH:-"$INPUTDIR"/jars/jcna-kldiv_15.jar}
# Run Java analysis with or without chromosome and DATAINFO
if [[ -n "$DATAINFO" && "$CHROMOSOME_JOB" == "true" ]]; then
echo "Running with data file & chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$DATAINFO" \
    "$SPECIES" \
    --chromosome "$CHR"
elif [[ -n "$DATAINFO" && "$CHROMOSOME_JOB" == "false" ]]; then
echo "Running with data file & no chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$DATAINFO" \
    "$SPECIES" 
elif [[ "$CHROMOSOME_JOB" == "true" ]]; then
echo "Running with no data file & chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$SPECIES" \
    --chromosome "$CHR"
else
echo "Running with no data file & no chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile=src/config/log4j2.xml -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$SPECIES"
fi
