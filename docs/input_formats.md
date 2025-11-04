# Input File Formats

## 🔬 genome.csv

Describes the reference genome used in the analysis.

**Required columns:**
- `chromosome`: Chromosome name (e.g., "chr1")
- `size`: Chromosome size'
- `fasta_path`: Absolute or container-mounted path to the chromosome FASTA file

**Example:**
chromosome,size,fasta_path
chr1,248956422,src/genome/human/hg38/chr1.fa
chr2,242193529,src/genome/human/hg38/chr2.fa

## 🧪 data.csv

Describes the input sample data, including control/case status.

**Required columns:**
- `sample_id`: Unique sample identifier
- `bam`: Path to alignment file in BAM format
- `iteration`: # times the same samples is analysed
- `status`: Diagnostic label (`control` or `case`)

**Example:**
H59_test5,samples/human/test5/SRR11394759.bam,H59,1,healthy
C60_test5,samples/human/test5/SRR11394760.bam,H60,1,case

## ⚙️ params.csv

Specifies preprocessing and filtering parameters.

** 1  column table - Required entries:**
- `repeat family`: composition analysis targets these DNA repeat families. If empty, the compositional analysis is skipped 

**Example:**
Alu
L1
centr

