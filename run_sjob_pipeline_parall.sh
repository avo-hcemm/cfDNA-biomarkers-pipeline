#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --job-name=pipeline_test0707
#SBATCH --output=output/pipeline_test0707_%a.out
#SBATCH --time=8-00:00:00
#SBATCH --cpus-per-task=50
#SBATCH --mem-per-cpu=5G
#SBATCH --ntasks=1
#SBATCH --array=0-22 # Array from 0 to number_of_chromosomes-1

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
GENOME_CSV=input/genome_allchr.csv
PARAMS_CSV=input/params-no-comp.csv
DATA_CSV=input/data-kldiv-max600_cases_58.csv
SPECIES=human

# Read the chromosome for this task
CHROM=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$GENOME_CSV" | cut -d',' -f1)

echo "Processing chromosome $CHROM on node $HOSTNAME, SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"

# Run the all pipeline
JAVA_HEAP=230g bash scripts/run_pipeline.sh \
 "$WORKDIR" \
 "$TESTSUBDIR"\
 "$ADAPTERFILE" \
 "$GENOMEINDEXFILE" \
 "$CHROM"\
 "$GENOME_CSV" \
 "$PARAMS_CSV" \
 "$SPECIES"
