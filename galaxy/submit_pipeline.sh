#!/bin/bash

# Fail fast and print commands
set -euo pipefail

# Load conda
source /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-11.5.0/miniconda3-24.7.1-fvzfyn26hdff63epca4yew2mktztjtjd/etc/profile.d/conda.sh
conda activate myenv2

# Parse input arguments
INPUTDIR="$1"
WORKDIR="$2"
TESTSUBDIR="$3"
ADAPTERFILE="$4"
GENOMEINDEXFILE="$5"
GENOMECSV="$6"
PARAMSCSV="$7"
DATACSV="$8"
SPECIES="$9"
OUTPUTDIR="${10}"

# Files & Folders validation

## Helper function to check file existence
check_file() {
  if [[ ! -f "$1" ]]; then
    echo "ERROR: File not found: $1"
    exit 1
  fi
}

## Helper function to check directory existence
check_dir() {
  if [[ ! -d "$1" ]]; then
    echo "ERROR: Directory not found: $1"
    exit 1
  fi
}

echo "🔍 Validating input paths..."

## Check required files
check_file "$ADAPTERFILE"
check_file "$GENOMEINDEXFILE"
check_file "$GENOMECSV"
check_file "$PARAMSCSV"
check_file "$DATACSV"

## Check required directories
check_dir "$INPUTDIR"
check_dir "$WORKDIR"

## Create output and working subdirectories if missing
mkdir -P "$INPUT/output"
mkdir -p "${WORKDIR}/${TESTSUBDIR}"
mkdir -p "$OUTPUTDIR"

echo "✅ All files and directories are in place."


# Submit job 1: module1
jobid1=$(sbatch --parsable <<EOF
#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --job-name=module1
#SBATCH --output=${INPUTDIR}/output/module1.out
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=4G
#SBATCH --ntasks=1

set -euo pipefail
source /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-11.5.0/miniconda3-24.7.1-fvzfyn26hdff63epca4yew2mktztjtjd/etc/profile.d/conda.sh
conda activate myenv2

bash scripts/run_pipeline_module1.sh \
  "$INPUTDIR" \
  "$WORKDIR" \
  "$TESTSUBDIR" \
  "$ADAPTERFILE" \
  "$GENOMEINDEXFILE" \
  "$OUTPUTDIR"
EOF
)

echo "Submitted job 1 (module1) with Job ID: $jobid1"

# Submit job 2: module2to6 as array
sbatch --dependency=afterok:$jobid1 <<EOF
#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --job-name=module2to6
#SBATCH --output=${INPUTDIR}/output/module2to6_%a.out
#SBATCH --time=8-00:00:00
#SBATCH --cpus-per-task=50
#SBATCH --mem-per-cpu=5G
#SBATCH --ntasks=1
#SBATCH --array=0-50

set -euo pipefail
source /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-11.5.0/miniconda3-24.7.1-fvzfyn26hdff63epca4yew2mktztjtjd/etc/profile.d/conda.sh
conda activate myenv2

NUM_CHROMS=\$((\$(wc -l < "$GENOMECSV") - 1))
if [ "\$SLURM_ARRAY_TASK_ID" -ge "\$NUM_CHROMS" ]; then
  echo "No chromosome assigned to task ID \$SLURM_ARRAY_TASK_ID. Exiting."
  exit 0
fi

CHROM=\$(sed -n "\$((SLURM_ARRAY_TASK_ID + 1))p" "$GENOMECSV" | cut -d',' -f1)
echo "Processing chromosome \$CHROM on node \$HOSTNAME"

bash scripts/run_pipeline_module2to6.sh \
  "$INPUTDIR" \
  "$GENOMECSV" \
  "$PARAMSCSV" \
  "$DATACSV" \
  "$SPECIES" \
  --chromosome "\$CHROM" \
  -o "$OUTPUTDIR"
EOF
