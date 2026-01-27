# Use Ubuntu as the base image
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    JAVA_HEAP=32g \
    OS_TYPE=linux-64

# Set working directory
WORKDIR /app
SHELL ["/bin/bash", "-c"]


# Install dependencies and Java 21 (Temurin)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    unzip \
    tar \
    curl \
    gnupg \
    software-properties-common \
    && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb noble main" \
        > /etc/apt/sources.list.d/adoptium.list \
    && wget -O- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor > /usr/share/keyrings/adoptium.gpg \
    && mkdir -p /usr/share/man/man1 \
    && apt-get update && apt-get install -y temurin-21-jdk \
    && apt-get purge -y gnupg && apt-get autoremove -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Define JAVA_HOME and prioritize it in PATH
ENV JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64
ENV PATH=$JAVA_HOME/bin:/opt/conda/bin:$PATH

# Install Miniforge (Conda)
RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O miniforge.sh && \
    bash miniforge.sh -b -p /opt/conda && \
    rm miniforge.sh

# Install bioinformatics tools (avoiding Java conflicts)
RUN conda install -y -c bioconda -c conda-forge \
    fastqc \
    trimmomatic \
    bowtie2 \
    samtools \
    multiqc \
    && conda clean -afy && rm -rf ~/.conda

# Copy pipeline files
COPY metadata/jars/jcna-biomrkrs-final_11.jar /app/jars/mod2to6.jar
COPY metadata/jars/libs/zstd-jni-1.5.7-4-linux_amd64.jar /app/libs/
COPY metadata/scripts/run_pipeline_module2to6.sh /app/
COPY metadata/scripts/reads_preprocessing.sh /app/
COPY metadata/config/log4j2.xml /app/config/

# Set CLASSPATH for Java
ENV CLASSPATH=/app/jars/mod2to6.jar:/app/libs/zstd-jni-1.5.7-4-linux_amd64.jar

# Default entrypoint
ENTRYPOINT ["bash", "/app/run_pipeline_module2to6.sh"]
