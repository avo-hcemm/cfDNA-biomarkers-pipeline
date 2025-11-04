# biomarkersearch-pipeline

This workflow is a bioinformatics pipeline to identify biomarkers from sequencing data derived from cell-free DNA in human plasma samples. The identified biomarkers can be used in downstream clinical applications, such as PCR-based screening and diagnostic tests. The Galaxy-based user interface allows users to upload data and monitor the progress of the workflow execution. The Galaxy server interacts with the SLURM scheduler to submit jobs to the specified HPC cluster.

## 🔍 Purpose

The pipeline performs preprocessing, alignment to the reference genome, and statistical analysis of input DNA sequencing data. It outputs a list of genomic sequences (approximately 200 bp) that are representative of the case groups, thereby serving as candidate biomarkers.

## 🧪 Key Features
* **Environmant:**
  - HPC setup (e.g., CPU configuration: 50 cores × 5 GB RAM)

* **Input:**
  - Paired-end FASTQ / FASTQ.GZ files  
  - Adapter file (FASTA format)  
  - CSV files for compositional and statistical analysis  

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
Launch the Galaxy workflow after adjusting the parameters in the job_config.xml file

