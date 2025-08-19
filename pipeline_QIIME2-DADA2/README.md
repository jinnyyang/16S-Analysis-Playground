# QIIME2_DADA2 Pipeline Guidelines
**Author:** Jinny Yang
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

### 2. Copy material to HPCC and start a job
a. If you have access to Lebeis lab file, open terminal page and commend and enter: 
```bash cp /mnt/research/LebeisLab/Yang/16SAmpliconWorkshop_20250819.zip .	```

b. Or download “16SAmpliconWorkshop_20250819.zip” from my OneDrive: https://michiganstate-my.sharepoint.com/:u:/g/personal/yangjinn_msu_edu/EXzCTBLp_xNLolFoeP5v1vcBXgEhIzXB45hRKTafg9J7dg?e=ZQgscE

Unzip the zip file: ```bash unzip 16SAmpliconWorkshop_20250819.zip . ```

Enter the file: ```bash cd 16SAmpliconWorkshop_20250819/HPCC ```

Run a job: ```bash sbatch cutadapt_Qiime2_DATA2_blastn.sh ```

