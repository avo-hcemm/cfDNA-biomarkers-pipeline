#!/bin/bash

set -euo pipefail

# Default values
GENOMEINFO=""
PARAMETERSINFO=""
DATAINFO=""
SPECIES=""
CHROMOSOME_JOB=false
CHR=""
OUTPUTDIR=""

echo "Raw arguments: $@"
echo "number raw arguments: $#"

# Trim function
trim() {
    local var="$*"
    # remove leading/trailing whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Apply trim
OUTPUTDIR="$(trim "$2")"
GENOMEINFO="$(trim "$3")"
PARAMETERSINFO="$(trim "$4")"

if [[ $# -eq 5 ]]; then
    SPECIES="$(trim "$5")"
elif [[ $# -eq 6 ]]; then
    DATAINFO="$(trim "$5")"
    SPECIES="$(trim "$6")"
elif [[ $# -eq 7 ]]; then
    SPECIES="$(trim "$5")"
    CHR="$(trim "$7")"
elif [[ $# -eq 8 ]]; then
    DATAINFO="$(trim "$5")"
    SPECIES="$(trim "$6")"
    CHR="$(trim "$8")"
fi


if [[ -n "$CHR" ]]; then
  CHROMOSOME_JOB=true
fi

# Validation
if [[ -z "$OUTPUTDIR"  || -z "$GENOMEINFO" || -z "$PARAMETERSINFO" || -z "$SPECIES" ]]; then
    echo "Usage: $0 -o <OUTPUTDIR> <GENOMEINFO.csv> <PARAMETERSINFO.csv> [DATAINFO.csv] <SPECIES> [--chromosome CHR]"
    exit 1
fi

echo "Current directory before 'cd' command:"
ls -lh 

echo "Running Java with arguments:"
echo "GENOMEINFO:${GENOMEINFO}"
echo "PARAMETERSINFO:$PARAMETERSINFO"
echo "DATAINFO:$DATAINFO"
echo "SPECIES:$SPECIES"
echo "OUTPUT DIR:$OUTPUTDIR"
echo "CHROMOSOME JOB:$CHR"
[[ "$CHROMOSOME_JOB" == "true" ]] && echo "Chromosome: $CHR"

if [[ -z "$OUTPUTDIR" ]]; then
  echo "Error: OUTPUTDIR is not specified. Use -o <output_dir>"
  exit 1
fi

cd "$OUTPUTDIR" || { echo "Error: Failed to change to $OUTPUTDIR"; exit 1; }
echo "Current directory after 'cd' command:"
ls -lh
echo "Input directory after 'cd' command:"
ls -lh input/*
echo "Samples directory after 'cd' command:"
ls -lh samples/*
echo "Show genome file content:"
head input/$SPECIES/genome.csv
# echo "Now in: $PWD"

# echo "check the actual file type"
# file input/genome.csv
# file $GENOMEINFO

# Auxiliary parameters to run the jar file
HEAP_SIZE=${JAVA_HEAP:-32g}
JAR_PATH=${JAR_PATH:-jars/jtool.jar}
LOGFILE_PATH=${LOGFILE_PATH:-config/log4j2.xml}
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
