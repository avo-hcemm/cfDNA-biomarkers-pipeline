# cfDNA-BiomarkerSearch-pipeline

This workflow is a bioinformatics pipeline to identify biomarker candidate sequences from WGS-shotgun sequencing data derived from cell-free DNA in human plasma samples. The identified biomarker candidates need to be validated using the qPCR assay. Once the validation tests have been completed, the identified biomarkers can be used in the clinical settings for PCR-based screening and diagnostic tests. The Galaxy-based user interface allows users to upload data and monitor the progress of the workflow execution. The Galaxy server interacts with the SLURM scheduler to submit jobs to the specified HPC cluster.

## 🔍 Purpose

The pipeline performs preprocessing, alignment to the reference genome, and statistical analysis of input DNA sequencing data. It outputs a list of genomic sequences (~ 200 bp) that are representative of the case groups, thereby serving as biomarker candidates.

## 🧪 Key Features
* **Environment:**
  - HPC setup with SLURM scheduler
  - Example configuration: up to 50 CPU cores × 5 GB RAM per core

* **Input:**
  - Paired-end FASTQ.GZ files (provided as a tar.gz archive)
  - Genome chromosomes (FASTA format, provided as a tar.gz archive) 
  - Bowtie2 index
  - CSV file with parameters for compositional analysis (list of repetitive families of DNA) 
  - CSV file with genome info (list of chromosomes, size, path_to_file/file_name)

  📎 For more details, refer to the [input format descriptions](docs/input_formats.md) and the [example template files](templates).

* **Output:**  
  - SVG files with plots of the coverage data and genomic coordinates associated with the candidate biomarker. 

* **Other Highlights:**  
  - Designed to support large datasets (over 100 samples) 
  - Allows simultaneous analysis of multiple cohorts
  - Integrates a custom Java tool with key bioinformatics utilities  
  - Can be installed on a local server, ensuring no data is shared on the cloud

## 🚀 Usage

### Run the pipeline 
Launch the Galaxy workflow after configuring the `job_config.xml` file to match the available HPC resources and SLURM setup.

## 🔁 Reproducibility

All tools used in this workflow are publicly available and versioned.  
Exact tool versions and parameters are embedded in the Galaxy workflow definition.

## 📂 Example input data

Example input files for testing the workflow are provided in the `metadata/data/` directory.

- `metadata/data/sample_data/`  
  Contains example paired-end `FASTQ.gz` files.

- `metadata/data/others/`  
  Contains the remaining input files, including genome FASTA files, Bowtie2 indices, and CSV metadata files.

These files allow users to test and explore the workflow without providing their own data.
