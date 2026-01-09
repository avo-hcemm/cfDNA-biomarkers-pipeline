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

echo "Number of arguments: $#"
for i in "$@"; do echo "[$i]"; done

# Trim function
trim() {
    local var="$*"
    # remove leading/trailing whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Apply trim
# Parse -o flag
if [[ "$1" == "-o" ]]; then
  OUTPUTDIR="$2"
  shift 2
else
  echo "Error: Missing -o flag. Usage: $0 -o <OUTPUTDIR> <GENOMEINFO.csv> <PARAMETERSINFO.csv> [DATAINFO.csv] <SPECIES> [--chromosome CHR]"
  exit 1
fi

GENOMEINFO="$(trim "$1")"
PARAMETERSINFO="$(trim "$2")"

if [[ $# -eq 3 ]]; then
    SPECIES="$(trim "$3")"
elif [[ $# -eq 4 ]]; then
    DATAINFO="$(trim "$3")"
    SPECIES="$(trim "$4")"
elif [[ $# -eq 5 ]]; then
    SPECIES="$(trim "$3")"
    CHR="$(trim "$5")"
elif [[ $# -eq 6 ]]; then
    DATAINFO="$(trim "$3")"
    SPECIES="$(trim "$4")"
    CHR="$(trim "$6")"
fi

if [[ -n "$CHR" ]]; then
  CHROMOSOME_JOB=true
fi

if [[ "$CHR" == *Y* || "$CHR" == *M* ]]; then
  echo "Chromosome $CHR is excluded from hte analysis. Exiting."
  exit 0;
fi

# Validation
if [[ -z "$OUTPUTDIR"  || -z "$GENOMEINFO" || -z "$PARAMETERSINFO" || -z "$SPECIES" ]]; then
    echo "Usage: $0 -o <OUTPUTDIR> <GENOMEINFO.csv> <PARAMETERSINFO.csv> [DATAINFO.csv] <SPECIES> [--chromosome CHR]"
    exit 1
fi

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

CPUS_PER_TASK=${GALAXY_SLOTS:-1}
TOTAL_MEM_MB=${GALAXY_MEMORY_MB:-32000}
MEM_PER_CPU_MB=$(( TOTAL_MEM_MB / CPUS_PER_TASK ))
HEAP_MEM_GB=$(( TOTAL_MEM_MB * 9 / 10240 ))  # 9/10 of total memory in GB

# Auxiliary parameters to run the jar file
# Define CLASSPATH if not already set in the environment
CLASSPATH=${CLASSPATH:-/app/jars/jcna-biomrkrs-final.jar:/app/libs/all-libraries.jar:/app/libs/zstd-jni-1.5.7-4-linux_amd64.jar}
HEAP_SIZE=${HEAP_MEM_GB:-32}G
LOGFILE_PATH=${LOGFILE_PATH:-/app/config/log4j2.xml}
echo "Java command: java -Xmx$HEAP_SIZE -Dlog4j.configurationFile=$LOGFILE_PATH -cp "$CLASSPATH" task.test.Jcna_input ..."

# Run Java analysis with or without chromosome and DATAINFO
if [[ -n "$DATAINFO" && "$CHROMOSOME_JOB" == "true" ]]; then
echo "Running with data file & chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -cp "$CLASSPATH" task.test.Jcna_input \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$DATAINFO" \
    "$SPECIES" \
    --chromosome "$CHR"
elif [[ -n "$DATAINFO" && "$CHROMOSOME_JOB" == "false" ]]; then
echo "Running with data file & no chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -cp "$CLASSPATH" task.test.Jcna_input \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$DATAINFO" \
    "$SPECIES" 
elif [[ "$CHROMOSOME_JOB" == "true" ]]; then
echo "Running with no data file & chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -cp "$CLASSPATH" task.test.Jcna_input \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$SPECIES" \
    --chromosome "$CHR"
else
echo "Running with no data file & no chromosome for the job"
  java -Xmx"$HEAP_SIZE" -Dlog4j.configurationFile="$LOGFILE_PATH" -cp "$CLASSPATH" task.test.Jcna_input \
    "$GENOMEINFO" \
    "$PARAMETERSINFO" \
    "$SPECIES"
fi
