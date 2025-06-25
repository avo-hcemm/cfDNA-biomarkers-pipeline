# Use an Ubuntu base image
FROM ubuntu:latest

ARG CONDA_VER=latest
ARG OS_TYPE=aarch64
ARG PY_VER=3.11

#working directory and subfolders
WORKDIR /app

#copy folders and subfolders in the working directory
COPY wdr/  /app/

# Install required packages for windowing system and additional tools
RUN apt-get update -y -q --fix-missing && apt-get install -yq \
    x11-apps \
    xauth \
    xserver-xorg-video-dummy \
    curl \
    wget \
    vim \
    unzip &&\
   rm -rf /var/lib/apt/lists/* && \
   curl -LO http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh && \
   bash Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh -p /miniconda -b && \
   rm Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh

# conda executable accessible from anywhere inside the docker container
ENV PATH=/miniconda/bin:${PATH}


#Install OpenJDK-21, Python, Perl, FastQC, Bowtie2	
RUN conda update -y conda && \
    conda install -c conda-forge -c bioconda fastqc trimmomatic bowtie2 openjdk=21 samtools picard

# Java environmental variable
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Java, Bowtie2,Fastqc executable accessible from anywhere inside the docker container
ENV PATH=$PATH:/opt/FastQC/:$JAVA_HOME/bin:$CONDA_DIR/bin:/opt/bowtie2

RUN chmod +x bash_scripts/reads_prep_dog.sh

#ENTRYPOINT ["bash_scripts/reads_prep_dog.sh"]
CMD ["/bin/bash"]
