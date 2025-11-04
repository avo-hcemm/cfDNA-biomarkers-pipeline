# biomarkersearch-pipeline

This container provides a bioinformatics pipeline to identify biomarkers from sequencing data derived from cell-free DNA in human plasma samples. The identified biomarkers can be used in downstream clinical applications, such as PCR-based screening and diagnostic tests.

## 🔍 Purpose

The pipeline performs preprocessing, alignment to the reference genome, and statistical analysis of input DNA sequencing data. It outputs a list of genomic sequences (approximately 200 bp) that are representative of the case groups, thereby serving as candidate biomarkers.

## 🧪 Key Features

* **Input:**
  - Paired-end FASTQ / FASTQ.GZ files  
  - Adapter file (FASTA format)  
  - CSV files for compositional and statistical analysis  

  📎 For more details, refer to the [input format descriptions](docs/input_formats.md) and the [example template files](templates).

* **Output:**  
  - SVG files with plots of the coverage data and genomic coordinates associated with the candidate biomarker. 

* **Other Highlights:**  
  - Designed to support large datasets (e.g., HPC environments)  
  - Integrates Java with key bioinformatics tools  
  - Compatible with Docker and Singularity

## 🚀 Usage

### Build the full pipeline container
` docker build -f dockerfiles/Dockerfile_pipeline -t avohcemm/biomarkersearch-pipeline:complete_v1.0.0 . `

### Docker

```bash
  docker run -it --rm \
   --platform linux/amd64 \
  -v /mnt/biomarkers-pipeline/jcna-kldiv_11.5.jar:/app/jcna-kldiv_11.5.jar \
  -v /mnt/biomarkers-pipeline/run_pipeline.sh:/app/run_pipeline.sh \
  -v /mnt/biomarkers-pipeline/wdr:/app/ \
  my-pipeline:latest \
  <directory-raw-data>
  <subdirectory-preprocessing> \
  <adapter_file> \
  <path-to-genomeinfo.csv> \
  <path-to-datainfo.csv> \
  <path-to-parameters.csv> \
  <species>
```
---

## 📄 Running Modules Separately

To run or submit the pipeline modules independently (e.g., in separate jobs), refer to [README_mod1to6.md](README_mod1to6.md) for detailed instructions.
