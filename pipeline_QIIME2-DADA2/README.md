# QIIME2_DADA2 Pipeline Guidelines
**Author:** Jinny Yang, Ph.D.  
**Email:** [yangjinn@msu.edu](mailto:yangjinn@msu.edu)  
**Date:** August 19, 2025

## Overview
This example pipeline is for training purposes only and was developed exclusively for the 16S workshop.

## Setup Instructions
To run this example pipeline, you need to:

### 1. Install QIIME2 on the HPCC at Michigan State University 
```bash
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml

module purge
module load Miniforge3

conda env create -n qiime2-2024.10 --file qiime2-amplicon-2024.10-py310-linux-conda.yml

rm qiime2-amplicon-2024.10-py310-linux-conda.yml
conda activate qiime2-2024.10
```

### 2. Clone the Workshop GitHub Repository
```bash
git clone https://github.com/jinnyyang/16S-Analysis-Playground.git
```

### 3. Copy raw sequences in cutadapt_QIIME2_DADA2/
    1. Download "RawSeq" file from:
    2. Upload to HPCC 
    3. Unzip the file: unzip RawSeq.zip 
  



