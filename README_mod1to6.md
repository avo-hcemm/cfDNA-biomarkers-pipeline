# biomarkersearch-pipeline

This container provides a bioinformatics pipeline to identify biomarkers from sequencing data derived from human plasma samples. The identified biomarkers can be used in downstream clinical applications such as PCR-based screening and diagnostic tests.

---

## 🔍 Purpose

The pipeline performs preprocessing, quality filtering, alignment, and statistical analysis of input DNA sequencing data. It outputs genomic regions (~200 bp) that are significantly enriched in case vs control groups — serving as candidate biomarkers.

---

## 🧪 Key Features

### **Input**
- Paired-end FASTQ / FASTQ.GZ files  
- Adapter file (FASTA format)  
- CSV files for compositional and statistical analysis  

📎 For more details, refer to the [input format descriptions](docs/input_formats.md) and the [example template files](templates).

### **Output**
- SVG files with plots of the coverage data and genomic coordinates associated with the candidate biomarker. 

### **Other Highlights**
- Designed to support large datasets (e.g., HPC environments)  
- Integrates Java and key bioinformatics tools  
- Compatible with Docker and Singularity

## 🐳 Docker Image

The Docker image for this pipeline is available on [Docker Hub](https://hub.docker.com/r/avohcemm/biomarkersearch-mod1to6).

You can pull it using:

```bash
docker pull avohcemm/biomarkersearch-mod1to6:v1.0.0
```
---
## 🚀 Usage

### 🔧 Build the Full Pipeline Container

```bash
docker build -f dockerfiles/Dockerfile_mod1to6 -t avohcemm/biomarkersearch-mod1to6:v1.0.0 .
```
---

### 🧼 Module 1 – Read Preprocessing & Alignment

This module performs:

- Adapter trimming  
- Quality filtering  
- Genome alignment (e.g., using Bowtie2)

#### **Positional Arguments**
- `<WORKDIR>` – Working directory to store intermediate files  
- `<TESTSUBDIR>` – Subfolder name under `WORKDIR`  
- `<ADAPTERFILE>` – Path to adapter FASTA file  
- `<GENOMEINDEX>` – Bowtie2 genome index prefix  

#### **Flags**
- `-i <INPUTDIR>` – Directory containing raw FASTQ/FASTQ.GZ files  
- `-o <OUTPUTDIR>` – Output directory for processed files  

> ✅ The order of positional arguments and flags does **not matter**.

#### **Example**
```bash
docker run -it --rm \
  --platform linux/amd64 \
  -v /full/path/to/rawdata:/app/sequencing \
  -v /full/path/to/workingdirectory:/app/wdr \
  avohcemm/biomarkersearch-mod1to6:v1.0.0 \
  /app/run_pipeline_module1.sh \
  <WORKDIR> \
  <TESTSUBDIR> \
  <ADAPTERFILE> \
  <GENOMEINDEX> \
  -i <INPUTDIR> \
  -o <OUTPUTDIR>
```

---

### 📊 Module 2–6 – Statistical Biomarker Discovery

This module processes aligned reads and computes biomarker regions using KL divergence, ML for feature extraction, and statistical validation.

#### **Positional Arguments**
- `<GENOME_CSV>` – Path to genome information CSV  
- `<PARAMS_CSV>` – Path to parameters configuration CSV  
- `<DATA_CSV>` – Path to dataset CSV (optional)  
- `<SPECIES>` – e.g., human  

#### **Flags**
- `-i <INPUTDIR>` – Directory with Java runnable JAR and log config file  
- `-o <OUTPUTDIR>` – Output directory for final biomarker results  
- `--chromosome <chr>` – Optional, run on one chromosome to increase performance  

> ✅ The order of positional arguments and flags does **not matter**.

#### **Example**
```bash
docker run -it --rm \
  --platform linux/amd64 \
  -v /full/path/to/javainputdir:/app/javainputdir \
  -v /full/path/to/output:/app/cfdna-biomarkers \
  avohcemm/biomarkersearch-mod1to6:v1.0.0 \
  <GENOME_CSV> \
  <PARAMS_CSV> \
  <DATA_CSV> \
  <SPECIES> \
  -i <INPUTDIR> \
  -o <OUTPUTDIR> \
  --chromosome <chr>
```

## 📁 File Structure

biomarkersearch-pipeline/
├── dockerfiles/
│ └── Dockerfile_mod1to6 # Dockerfile for building the full pipeline
├── metadata/scripts/
│ ├── run_pipeline_module1.sh # Bash script for Module 1 (read preprocessing & alignment)
│ └── run_pipeline_module2to6.sh # Bash script for Modules 2–6 (statistical biomarker discovery)
├── metadata/templates/
│ ├── genome.csv # Genome configuration template
│ ├── params.csv # Pipeline parameter template
│ └── data.csv # Sample dataset template (optional)
├── docs/
│ └── input_formats.md # Detailed input format specifications
├── jcna-kldiv_15.2.jar # Java tool for biomarker discovery
└── README_mod1to6.md # Project documentation