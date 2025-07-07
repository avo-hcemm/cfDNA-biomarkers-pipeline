#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --job-name=klDiv_max600_cases_no-comp
#SBATCH --output=output/klDiv_max600_cases_no-comp_%a_04.2.out
#SBATCH --time=8-00:00:00
#SBATCH --cpus-per-task=50
#SBATCH --mem-per-cpu=5G
#SBATCH --ntasks=1
#SBATCH --array=0-22  # Array from 0 to number_of_chromosomes-1

# Setup
source /opt/ohpc/pub/apps/spack/local/linux-almalinux9-zen3/gcc-11.5.0/miniconda3-24.7.1-fvzfyn26hdff63epca4yew2mktztjtjd/etc/profile.d/conda.sh
ulimit -v unlimited
conda activate myenv2
cd /scratch/csensen/jcna_test

# Path to your CSV files
GENOME_CSV=input/genome_allchr.csv
PARAMS_CSV=input/params-no-comp.csv
DATA_CSV=input/data-kldiv-max600_cases_58.csv

# Read the chromosome for this task
CHROM=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$GENOME_CSV" | cut -d',' -f1)

echo "Processing chromosome $CHROM on node $HOSTNAME, SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"

# Run with dynamic input based on index
java -Xmx230g -Dlog4j.configurationFile=src/config/log4j2.xml \
-jar /home/avo/jars/jcna-kldiv_14.jar \
$CHROM \
"$GENOME_CSV" \
"$PARAMS_CSV" \
"$DATA_CSV" \
human

