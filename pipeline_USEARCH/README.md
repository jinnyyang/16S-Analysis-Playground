# USEARCH pipeline guidelies

**Author:** Gian M. N. Benucci, Ph.D.  
**Email:** [benucci@msu.edu](mailto:benucci@msu.edu)  
**Date:** August 22, 2022

## 1) doenload USEARCH
### commands at  https://www.drive5.com/usearch/manual/cmds_all.html
### usearch insaller https://rcedgar.github.io/usearch12_documentation/install.html
### older binaries https://github.com/rcedgar/usearch_old_binaries/
## 2) Copy binary to HPCC
`scp Downloads/usearch11.0.667_i86linux64 \
	benucci@rsync.hpcc.msu.edu:/mnt/research/glbrc_group/benuccigmn/projects/project_Workshop16S/16S-Analysis-Playground/pipeline_USEARCH/usearch/`
## 3) make binaries executable
`cd usearch`
`chmod +x usearch_linux_x86_12.0-beta`


