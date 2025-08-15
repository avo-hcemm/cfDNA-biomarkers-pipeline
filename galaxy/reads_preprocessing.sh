#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

for tool in trimmomatic fastqc bowtie2 samtools picard multiqc; do
  if ! command -v "$tool" &> /dev/null; then
    echo "Error: Required tool '$tool' not found in PATH"
    exit 1
  fi
done

#Set up variables
OUTPUTDIR=""
PATHTODATA=""
DATA_SUBDIR=""
ADAPTERFILE=""
GENOMEINDEX=""
THREADS=10
	

if [ $# -ne 6 ]; then
  echo "Usage: $0 -o <outputDir> <pathToData> <dataSubdir> <adapterFile> <genomeIndex>"
  exit 1
fi

# Trim function
trim() {
    local var="$*"
    # remove leading/trailing whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

OUTPUTDIR="$(trim "$2")"
PATHTODATA="$(trim "$3")"
DATA_SUBDIR="$(trim "$4")"
ADAPTERFILE="$(trim "$5")"
GENOMEINDEX="$(trim "$6")"

echo "Input Parameters after assignment:"
echo "OUTPUTDIR=$OUTPUTDIR"
echo "PATHTODATA=$PATHTODATA"
echo "DATA_SUBDIR=$DATA_SUBDIR"
echo "ADAPTERFILE=$ADAPTERFILE"
echo "GENOMEINDEX=$GENOMEINDEX"

if [[ -z "$OUTPUTDIR" ]]; then
    echo "Error: -o OUTPUTDIR must be specified"
    exit 1
fi

echo "Current directory: $PWD"
ls -lh "$PWD/"
ls -lh "$PATHTODATA/"

echo "start date: $(date +%d%m%Y,%H:%M:%S)"


for subdir in "${PATHTODATA%/}"/*/; do
  echo "subdirectory: $subdir"
  subfolder_name=$(basename "$subdir")
  echo "Processing subfolder: $subfolder_name"
  
  shopt -s nullglob
  files=("${subdir}"*_R1.fastq.gz)
  shopt -u nullglob
  
  if [ ${#files[@]} -eq 0 ]; then
 	echo "No R1 fastq files found in $subdir, skipping."
	continue
  fi
 
 # Define dynamic output folders based on subfolder name
  untrimm_dir="$subdir"
  untrimm_log_dir="$subdir/untrimm/log/"
  untrimm_fastqc_dir="$subdir/untrimm/untrimm_fastqc/"
  untrimm_multiqc_dir="$untrimm_fastqc_dir/untrimm_multiqc"
  trimm_dir="$PATHTODATA/trimm/${DATA_SUBDIR}/${subfolder_name}"
  trimm_log_dir="$PATHTODATA/trimm/log/${DATA_SUBDIR}/${subfolder_name}"
  trimm_fastqc_dir="$PATHTODATA/trimm/trimm_fastqc/${DATA_SUBDIR}/${subfolder_name}"
  trimm_multiqc_dir="$PATHTODATA/trimm/trimm_fastqc/trimm_multiqc/${DATA_SUBDIR}/${subfolder_name}" 
  mapped_dir="$PATHTODATA/mapped/${DATA_SUBDIR}/${subfolder_name}"
  mapped_log_dir="$PATHTODATA/mapped/log/${DATA_SUBDIR}/${subfolder_name}"
  mapped_fastqc_dir="$PATHTODATA/mapped/mapped_fastqc/${DATA_SUBDIR}/${subfolder_name}/"
  mapped_multiqc_dir="$PATHTODATA/mapped/mapped_fastqc/mapped_multiqc/${DATA_SUBDIR}/${subfolder_name}"

  echo "Creating directories..."
  mkdir -p "$untrimm_log_dir" "$untrimm_fastqc_dir" "$untrimm_multiqc_dir" \
  "$trimm_dir" "$trimm_log_dir" "$trimm_fastqc_dir" "$trimm_multiqc_dir" \
  "$mapped_dir" "$mapped_log_dir" "$mapped_fastqc_dir" "$mapped_multiqc_dir"
    
  if [ $? -eq 0 ]; then
      echo "Directories created successfully."
  else
      echo "Failed to create one or more directories."
  fi

  for file in "${files[@]}"; do
    withpath=${file}
    filename=${withpath##*/}
    echo "$filename"
    base="${filename%%_R1*}"  # base extraction
    echo -e "Next sample to process is ${base}"
    
    if [ ! -f "$untrimm_dir/${base}_R2.fastq.gz" ]; then
		echo "Warning: Missing paired files for sample ${base} in $subdir. Skipping."
	    continue
  	fi

    echo 'Fastqc on raw sequencing data'
  
    fastqc -t "$THREADS" --noextract -f fastq -o "$untrimm_fastqc_dir" \
      "$untrimm_dir/${base}_R1.fastq.gz" "$untrimm_dir/${base}_R2.fastq.gz" || { echo "fastqc on untrimmed files failed"; exit 1; }

    echo 'Trimmomatic is running'

    trimmomatic PE -threads "$THREADS" -phred33 -trimlog "$trimm_log_dir/trimm_${base}_log.log" \
      "$untrimm_dir/${base}_R1.fastq.gz" "$untrimm_dir/${base}_R2.fastq.gz" \
      "$trimm_dir/${base}_1-trimmP.fastq.gz" "$trimm_dir/${base}_1-trimmU.fastq.gz" \
      "$trimm_dir/${base}_2-trimmP.fastq.gz" "$trimm_dir/${base}_2-trimmU.fastq.gz" \
      ILLUMINACLIP:"$ADAPTERFILE":2:30:10 SLIDINGWINDOW:4:20 MAXINFO:25:0.2 MINLEN:60 || { echo "trimmomatic failed"; exit 1; }

    echo 'Fastqc is running'
    fastqc -t "$THREADS" --noextract -f fastq -o "$trimm_fastqc_dir" \
      "$trimm_dir/${base}_1-trimmP.fastq.gz" "$trimm_dir/${base}_2-trimmP.fastq.gz" \
      "$trimm_dir/${base}_1-trimmU.fastq.gz" "$trimm_dir/${base}_2-trimmU.fastq.gz" || { echo "fastqc on trimmed files failed"; exit 1; }

    echo 'Bowtie2 is running'
    bowtie2 --threads "$THREADS" --phred33 --local --minins 100 --maxins 600 --no-discordant --no-mixed \
      -x "$GENOMEINDEX" \
      -1 "$trimm_dir/${base}_1-trimmP.fastq.gz" \
      -2 "$trimm_dir/${base}_2-trimmP.fastq.gz" \
      -S "$mapped_dir/${base}.sam" 2>"$mapped_log_dir/bowtie2_${base}_logfile.log" || { echo "bowtie2 failed"; exit 1; }

    echo 'Samtools sorting BAM'
    samtools sort -o "$mapped_dir/${base}_sort.bam" "$mapped_dir/${base}.sam" || { echo "samtools sort failed"; exit 1; }
    
    rm "$mapped_dir/${base}.sam"
    
    echo 'Adding read groups to BAM ...'
	picard AddOrReplaceReadGroups \
  		--INPUT "$mapped_dir/${base}_sort.bam" \
  		--OUTPUT "$mapped_dir/${base}_sort_rg.bam" \
  		--RGID "${base}" \
  		--RGLB "lib1" \
  		--RGPL "ILLUMINA" \
  		--RGPU "unit1" \
  		--RGSM "${base}"

    echo 'mark-remove-duplicates picard tool is runnning ...'
    picard MarkDuplicates \
    -I "$mapped_dir/${base}_sort_rg.bam" \
    -O "$mapped_dir/${base}_sort_ndp.bam" \
    -M "$mapped_dir/${base}_sort_ndp_metrics.txt" \
    --REMOVE_DUPLICATES true || echo "MarkDuplicates on sorted bam files failed. Skipping ..."

    echo 'Fastqc on BAM'
    if [ -f "$mapped_dir/${base}_sort_ndp.bam" ]; then
      FINAL_BAM="${mapped_dir}/${base}_sort_ndp.bam"
    else
      FINAL_BAM="${mapped_dir}/${base}_sort.bam"
    fi
    fastqc -t "$THREADS" --noextract -f bam -o "$mapped_fastqc_dir" "$FINAL_BAM"|| { echo "fastqc on bam files failed"; exit 1; } 

    # sampels moved to target folder for Java analysis
    echo "creating the folder $OUTPUTDIR/human/${subfolder_name}/ if it does not exists"
    mkdir -p "$OUTPUTDIR/human/${subfolder_name}/"
    if [ -f "$mapped_dir/${base}_sort_ndp.bam" ]; then
      cp "$mapped_dir/${base}_sort_ndp.bam" "$OUTPUTDIR/human/${subfolder_name}/${base}_sort_ndp.bam"
      echo "${base}_sort_ndp.bam copied to folder $OUTPUTDIR/human/${subfolder_name}/${base}_sort_ndp.bam."
    else
      cp "$mapped_dir/${base}_sort.bam" "$OUTPUTDIR/human/${subfolder_name}/${base}_sort.bam"
      echo "${base}_sort.bam copied to folder $OUTPUTDIR/human/${subfolder_name}/${base}_sort.bam."
    fi


  done

  # Run MultiQC for untrimmed fastqc results
  if compgen -G "${untrimm_fastqc_dir}"/*.zip > /dev/null 2>&1; then
      echo "Running MultiQC for untrimmed: ${subfolder_name}"
      multiqc "$untrimm_fastqc_dir" \
        -o "$untrimm_multiqc_dir" \
        -n "multiqc_untrimm_${DATA_SUBDIR}"
  else
      echo "No FASTQC zip files found for $subfolder_name (untrimmed), skipping MultiQC."
  fi
  
  # Run MultiQC for trimmed fastqc results
	if compgen -G "${trimm_fastqc_dir}"/*.zip > /dev/null 2>&1; then
	    echo "Running MultiQC for trimmed: ${subfolder_name}"
	    multiqc "$trimm_fastqc_dir" \
        -o "$trimm_multiqc_dir" \
        -n "multiqc_trimm_${DATA_SUBDIR}"
	else
    	echo "No FASTQC zip files found for $subfolder_name (trimmed), skipping MultiQC."
	fi

	# Run MultiQC for mapped fastqc results
	if compgen -G "${mapped_fastqc_dir}"/*.zip > /dev/null 2>&1; then
	    echo "Running MultiQC for mapped: ${subfolder_name}"
	    multiqc "$mapped_fastqc_dir" \
        -o "$mapped_multiqc_dir" \
        -n "multiqc_mapped_${DATA_SUBDIR}"
	else
    	echo "No FASTQC zip files found for $subfolder_name (mapped), skipping MultiQC."
	fi

done

echo "end date: $(date +"%d%m%Y,%H:%M:%S")"


