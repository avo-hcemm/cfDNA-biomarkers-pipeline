#!/bin/bash

# $1 is the output directory to scan for BAM files
OUTPUTDIR=$1
OUTFILE=$2

# Empty or create the output file
echo -e "name\tfile" > "$OUTFILE"

# Find all .bam files recursively inside $OUTPUTDIR
find "$OUTPUTDIR" -type f -name '*.bam' | while read -r bamfile; do
  # Extract just the filename without extension for the name column
  base=$(basename "$bamfile" .bam)
  # Write a line with "name<TAB>full_path"
  echo -e "${base}\t${bamfile}" >> "$OUTFILE"
done
