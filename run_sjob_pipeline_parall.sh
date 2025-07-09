#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --job-name=pipeline_test0709
#SBATCH --output=output/pipeline_test0709_%a.out
#SBATCH --time=8-00:00:00
#SBATCH --cpus-per-task=50
#SBATCH --mem-per-cpu=5G
#SBATCH --ntasks=1
#SBATCH --array=0-50 # Array from 0 to number_of_chromosomes-1

set -euo pipefail

CPUS_PER_TASK=${SLURM_CPUS_PER_TASK:-50}          # fallback to 50 if not set
MEM_PER_CPU=${SLURM_MEM_PER_CPU:-5000}            # in MB; fallback to 5000MB (5G)
MEM_PER_CPU_GB=$(( MEM_PER_CPU / 1024 ))      # Convert MEM_PER_CPU to GB (divide by 1024)
TOTAL_MEM_GB=$(( CPUS_PER_TASK * MEM_PER_CPU_GB ))  # Calculate total memory in GB                  
HEAP_MEM_GB=$(( TOTAL_MEM_GB * 9 / 10 ))      # Reserve some memory for system overhead, e.g., 10%

JAVA_HEAP="${HEAP_MEM_GB}g"

echo "Using Java heap size: $JAVA_HEAP"

# Setup
source /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-11.5.0/miniconda3-24.7.1-fvzfyn26hdff63epca4yew2mktztjtjd/etc/profile.d/conda.sh
ulimit -v unlimited
conda activate myenv2


# Absolute paths to your CSV files
# Must be entered in this order
INPUTDIR=/scratch/csensen
WORKDIR=/scratch/csensen/Genomics/sequencing/newtest 
TESTSUBDIR=testAll0709
ADAPTERFILE=/scratch/csensen/Genomics/sequencing/adapter/NexteraXT-Trans-Prefix.fa
GENOMEINDEXFILE=/scratch/csensen/Genomics/sequencing/genome_hg38/hg38_filtered_index
GENOME_CSV=/scratch/csensen/jcna_test/input/human/genome_allchr.csv
PARAMS_CSV=/scratch/csensen/jcna_test/input/human/params-no-comp.csv
DATA_CSV=/scratch/csensen/jcna_test/input/human/data-kldiv-max600_cases_29.csv  # the control group must be labelled "healthy"
SPECIES=human
OUTPUTDIR=/scratch/csensen/jcna_test/
mkdir -p "$OUTPUTDIR"

# FLAGS
# -s: skip preprocessing
# -chromosome: analysis for that specific chromosome
# -o: output folder

NUM_CHROMS=$(($(wc -l < "$GENOME_CSV") - 1))
if [ "$SLURM_ARRAY_TASK_ID" -ge "$NUM_CHROMS" ]; then
  echo "No chromosome assigned to task ID $SLURM_ARRAY_TASK_ID. Exiting."
  exit 0
fi


# Read the chromosome for this task
CHROM="$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$GENOME_CSV" | cut -d',' -f1)"

echo "Processing chromosome $CHROM on node $HOSTNAME, SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"

export JAVA_HEAP="$JAVA_HEAP"

# Run the all pipeline
bash scripts/run_pipeline_v03.sh \
 "$GENOME_CSV" \
 "$PARAMS_CSV" \
 "$DATA_CSV" \
 "$SPECIES" \
 --chromosome "$CHROM" \
 -o "$OUTPUTDIR" \
 -i "$INPUTDIR" \
 -s
