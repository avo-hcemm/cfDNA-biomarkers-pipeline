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

# Validation of args length 
if [[ "${#ARGS[@]}" -lt 3 ]]; then
  echo "Usage (skipping preprocessing): $0 <GENOMEINFO.csv> <PARAMETERSINFO.csv> [DATAINFO.csv] <SPECIES> [--chromosome CHR] -i <INPUTDIR> -o <OUTPUTDIR>"
  exit 1
fi

# Assign arguments based on the args length
if [[ "${#ARGS[@]}" -eq 4 ]]; then
  GENOMEINFO=${ARGS[0]}
  PARAMETERSINFO=${ARGS[1]}
  DATAINFO=${ARGS[2]}
  SPECIES=${ARGS[3]}
elif [[ "${#ARGS[@]}" -eq 3 ]]; then
  GENOMEINFO=${ARGS[0]}
  PARAMETERSINFO=${ARGS[1]}
  SPECIES=${ARGS[2]}
  DATAINFO=""
fi

# Default max heap size if not provided


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

# Auxiliary parameters to run the jar file
HEAP_SIZE=${JAVA_HEAP:-32g}
JAR_PATH=${JAR_PATH:-"$INPUTDIR"/jars/jcna-kldiv_16.jar}
LOGFILE_PATH="$INPUTDIR"/config/log4j2.xml
echo "Java command: java -Xmx$HEAP_SIZE -Dlog4j.configurationFile=$LOGFILE_PATH -jar $JAR_PATH ..."

# Run Java analysis with or without chromosome and DATAINFO
if [[ -n "$DATAINFO" && "$CHROMOSOME_JOB" == "true" ]]; then
echo "Running with data file & chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$DATAINFO" \
    "$SPECIES" \
    --chromosome "$CHR"
elif [[ -n "$DATAINFO" && "$CHROMOSOME_JOB" == "false" ]]; then
echo "Running with data file & no chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$DATAINFO" \
    "$SPECIES" 
elif [[ "$CHROMOSOME_JOB" == "true" ]]; then
echo "Running with no data file & chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$SPECIES" \
    --chromosome "$CHR"
else
echo "Running with no data file & no chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -jar \
    "$JAR_PATH" \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$SPECIES"
fi
