#!/bin/bash

# Input files
GENOME_FA="genome.fa"
CHROM_LIST="retain_sequences.txt"
OUTPUT_FA="genome_selected_chr.fa"
INDEX_DIR="genome"

# Make sure the fasta is indexed
if [ ! -f "${GENOME_FA}.fai" ]; then
    echo "Indexing genome fasta..."
    samtools faidx "$GENOME_FA"
fi

# Extract the desired chromosomes into a new fasta
echo "Extracting chromosomes..."
# Only keep chromosomes that exist in the .fai file
CHROMS=$(grep -Fxf "$CHROM_LIST" "${GENOME_FA}.fai" | cut -f1)
if [ -z "$CHROMS" ]; then
    echo "No matching chromosomes found in $GENOME_FA!"
    exit 1
fi

samtools faidx "$GENOME_FA" $CHROMS > "$OUTPUT_FA"
echo "Created $OUTPUT_FA"

# Create directory for index
mkdir -p "$INDEX_DIR"

# Build Bowtie2 index
bowtie2-build "$OUTPUT_FA" "$INDEX_DIR/genome_selected_chr_index"
if [ $? -eq 0 ]; then
    echo "Done! Bowtie2 index created in $INDEX_DIR/"
else
    echo "Error: Bowtie2 index creation failed."
    exit 1
fi
