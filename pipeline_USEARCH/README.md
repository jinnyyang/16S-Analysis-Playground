# USEARCH Pipeline Guidelines
**Author:** Gian M. N. Benucci, Ph.D.  
**Email:** [benucci@msu.edu](mailto:benucci@msu.edu)  
**Date:** August 22, 2022

## Overview
This example pipeline is for training purposes only and was developed exclusively for the 16S workshop. If you are planning to use USEARCH to analyze your data, please use [Cecilia](https://github.com/Gian77/Cecilia), a more robust and sophisticated workflow.

## Setup Instructions
To run this example pipeline, you need to:

### 1. Clone the Workshop GitHub Repository
```bash
git clone https://github.com/jinnyyang/16S-Analysis-Playground.git
```

### 2. Download USEARCH Binary
Visit the following resources:
- All commands: https://www.drive5.com/usearch/manual/cmds_all.html
- USEARCH installer: https://rcedgar.github.io/usearch12_documentation/install.html
- Older binaries: https://github.com/rcedgar/usearch_old_binaries/

**Note:** USEARCH v11 or later is preferred as it has more functionalities.

### 3. Copy Binaries to the HPCC at Michigan State University (or Your Computer)
```bash
scp Downloads/usearch11.0.667_i86linux64 benucci@rsync.hpcc.msu.edu:/mnt/home/benucci/16S-Analysis-Playground/pipeline_USEARCH/usearch/
```

### 4. Make USEARCH Binaries Executable
```bash
cd usearch
chmod +x usearch11.0.667_i86linux64
```
