#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --job-name=pipeline_test0707
#SBATCH --output=output/pipeline_test0707_%a.out
#SBATCH --time=8-00:00:00
#SBATCH --cpus-per-task=50
#SBATCH --mem-per-cpu=5G
#SBATCH --ntasks=1
#SBATCH --array=0-22 # Array from 0 to number_of_chromosomes-1

# Get SLURM variables
CPUS_PER_TASK=${SLURM_CPUS_PER_TASK:-50}      # fallback to 50 if not set
MEM_PER_CPU=${SLURM_MEM_PER_CPU:-5000}        # in MB; fallback to 5000MB (5G)

# Convert MEM_PER_CPU to GB (divide by 1024)
MEM_PER_CPU_GB=$(( MEM_PER_CPU / 1024 ))

# Calculate total memory in GB
TOTAL_MEM_GB=$(( CPUS_PER_TASK * MEM_PER_CPU_GB ))

# Reserve some memory for system overhead, e.g., 10%
HEAP_MEM_GB=$(( TOTAL_MEM_GB * 9 / 10 ))

# Set heap size as Xmx argument string
JAVA_HEAP="${HEAP_MEM_GB}g"

echo "Using Java heap size: $JAVA_HEAP"

# Setup
source /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-11.5.0/miniconda3-24.7.1-fvzfyn26hdff63epca4yew2mktztjtjd/etc/profile.d/conda.sh
ulimit -v unlimited
conda activate myenv2

cd /scratch/csensen

# Path to your CSV files
WORKDIR=Genomics/sequencing/newtest 
TESTSUBDIR=testAll0701
ADAPTERFILE=Genomics/sequencing/adapter/NexteraXT-Trans-Prefix.fa
GENOMEINDEXFILE=Genomics/sequencing/genome_hg38/hg38_filtered_index
GENOME_CSV=jcna_test/input/genome_allchr.csv
PARAMS_CSV=jcna_test/input/params-no-comp.csv
DATA_CSV=jcna_test/input/data-kldiv-max600_cases_58.csv
SPECIES=human

# Read the chromosome for this task
CHROM="$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$GENOME_CSV" | cut -d',' -f1)"

echo "Processing chromosome $CHROM on node $HOSTNAME, SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"

export JAVA_HEAP="$JAVA_HEAP"
# Run the all pipeline
bash scripts/run_pipeline_v03.sh \
 #"$WORKDIR" \
 #"$TESTSUBDIR" \
 #"$ADAPTERFILE" \
 #"$GENOMEINDEXFILE" \
 "$GENOME_CSV" \
 "$PARAMS_CSV" \
 "$SPECIES" \
 --chromosome "$CHROM" \
 -s