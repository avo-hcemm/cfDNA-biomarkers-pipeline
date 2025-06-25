# biomarkersearch-pipeline

This container provides a bioinformatics pipeline to identify biomarkers from sequencing data derived from human plasma samples. The biomarkers can be used in downstream clinical applications such as PCR-based screening and diagnostic tests.

## 🔍 Purpose

The pipeline performs preprocessing, quality filtering, alignment, and statistical analysis of input DNA sequencing data. It outputs genomic regions (\~200 bp) that are significantly enriched in case vs control groups — serving as candidate biomarkers.

## 🧪 Key Features

* **Input:**
  - Paired-end FASTQ / FASTQ.GZ files  
  - Adapter file (FASTA format)  
  - CSV files for compositional and statistical analysis  

  📎 For more details, refer to the [input format descriptions](docs/input_formats.md) and the [example template files](templates).

* **Output:**  
  - CSV file listing biomarker sequences with associated genomic coordinates

* **Other Highlights:**  
  - Designed to support large datasets (e.g., HPC environments)  
  - Integrates Java and key bioinformatics tools  
  - Compatible with Docker and Singularity

## 🚀 Usage

### Build the full pipeline container
docker build -f dockerfiles/Dockerfile_pipeline -t avohcemm/biomarkersearch-pipeline:complete_v1.0.0 .

### Docker

```bash
  docker run -it --rm \
  -v /path/to/bash_scripts:/app/sequencing/bash_scripts \
  -v /path/to/sequencing_adapter:/app/sequencing/adapter \
  -v /path/to/sequencing_untrimm:/app/sequencing/untrimm \
  -v /path/to/sequencing_genome_hg38:/app/sequencing/genome_hg38 \
  -v /path/to/input_folder:/app/input/human \
  -v /path/to/samples:/app/samples \
  -v /path/to/genome:/app/src/genome \
  my-pipeline:latest \
  <directory-raw-data>
  <subdirectory-preprocessing> \
  <adapter_file> \
  <path-to-genomeinfo.csv> \
  <path-to-datainfo.csv> \
  <path-to-parameters.csv> \
  <species>
```
