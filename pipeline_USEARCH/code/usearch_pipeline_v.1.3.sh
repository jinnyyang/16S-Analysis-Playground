#!/bin/bash

# USEARCH PIPELINE: usearch_pipeline_v.1.3.sh

# BEFORE you start, read the README file!
# You MUST have:
# * a rawdata directory with the raw demultiplexed fastqs
# * a code directory with the config.cnf and the usearch_pipeline_v.1.3.sh
# * a usearch/ directory with the USEARCH executable inside (README file with info)

# source the config
source /mnt/research/glbrc_group/benuccigmn/projects/project_Workshop16S/16S-Analysis-Playground/pipeline_USEARCH/code/config.cnf

# directories from github
tree $WORK_DIR/pipeline_USEARCH/closedref_db
tree $WORK_DIR/pipeline_USEARCH/taxonomy_db
tree $WORK_DIR/pipeline_USEARCH/primers
tree $WORK_DIR/pipeline_USEARCH/code
tree $WORK_DIR/pipeline_USEARCH/usearch

# generate directories 
mkdir -p $WORK_DIR/pipeline_USEARCH/stats
mkdir -p $WORK_DIR/pipeline_USEARCH/results
mkdir -p $WORK_DIR/pipeline_USEARCH/results/nophix
mkdir -p $WORK_DIR/pipeline_USEARCH/results/merged
mkdir -p $WORK_DIR/pipeline_USEARCH/results/noprimer
mkdir -p $WORK_DIR/pipeline_USEARCH/results/exp_errors
mkdir -p $WORK_DIR/pipeline_USEARCH/results/filtered
mkdir -p $WORK_DIR/pipeline_USEARCH/results/dereplicated
mkdir -p $WORK_DIR/pipeline_USEARCH/results/asvs
mkdir -p $WORK_DIR/pipeline_USEARCH/results/otus
mkdir -p $WORK_DIR/pipeline_USEARCH/results/taxonomy_assignments
mkdir -p $WORK_DIR/pipeline_USEARCH/logs

# unzip the reads
for gz in $WORK_DIR/rawdata/*.fastq.gz; do echo $gz; gunzip -k $gz; done 

# count reads
for file in $WORK_DIR/rawdata/*.fastq; do base=$(basename "$file" _001.fastq); echo "$base : `echo $(cat ${file} | wc -l)/4|bc`"; done > $WORK_DIR/pipeline_USEARCH/stats/1.raw_reads.counts

# make a list of all raw reads
ls $WORK_DIR/rawdata/*.fastq  > $WORK_DIR/rawdata/fastq_raw.list

# 0.1) filter Phix ------------------------------------------------------#
# reason: we remove phix reads and match R1 and R2 to pairs
while read R1; do read R2; echo $R1; base=$(basename "$R1" R1_001.fastq); $USEARCH -filter_phix "$R1" -reverse "$R2" -output "$WORK_DIR/pipeline_USEARCH/results/nophix/${base}R1_nophix.fastq" -output2 "$WORK_DIR/pipeline_USEARCH/results/nophix/${base}R2_nophix.fastq"; done < $WORK_DIR/rawdata/fastq_raw.list 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/nophix.log

#NOTE the nophix.log is optional, just to keep record fo what outputted on the screen.
rm $WORK_DIR/rawdata/fastq_raw.list

# count reads
for file in $WORK_DIR/pipeline_USEARCH/results/nophix/*.fastq; do base=$(basename "$file" R1_001.fastq); echo "$base : `echo $(cat ${file} | wc -l)/4|bc`"; done > $WORK_DIR/pipeline_USEARCH/stats/2.nophix.counts

# 0.2) merge pairs ------------------------------------------------------#
# reason: we can now merge merging multiple fastq files in a single command
# NOTE. You can perform some filtering before merging, depending on reads quality, length, overlap etc.
# Sanity check is important before this step! See fastqc for this.
# commands: https://www.drive5.com/usearch/manual/cmd_fastq_mergepairs.html
# parameters: https://www.drive5.com/usearch/manual/merge_options.html
# possible overlaps https://www.drive5.com/usearch/manual/merge_length_range.html
$USEARCH -fastq_mergepairs $WORK_DIR/pipeline_USEARCH/results/nophix/*_R1_*.fastq -relabel @ -fastqout $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/merged.log

# count reads
sed -n '1~4p' $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq | awk -F'.' '{print $1}' | sed 's/^@//' | sort | uniq -c > $WORK_DIR/pipeline_USEARCH/stats/3.merged.counts

# NOTE. Now reads are merged in one single file so you need to use a different strategy
# NOTE. Sample names is important. If you want to keep the full sample name, or a different portion of it, then you need to rewrite the name before running USEARCH.

# 0.3) trim primers ------------------------------------------------------#
# reason:
# * primers may contain sequecing errors
# * low quality usually at the 5' end where primers are located
# * primer sequences are NOT part of the actuall biological target sequence
# * can interfere with database searches and taxonomic assignment, databases typically don't include primer sequences, so leaving them in creates mismatches
# * can skew diversity calculations and distance metrics (e.g. phylogenetics)

# use: cutadapt to match the primer seuence (more accurate and precise).
# cutadapt recosngize the primer sequence and remove it accordignly form th reads and everythign that extends further. 
# cutadapt has parameters to adjust how stringent the trimming will be to your liking.

# To use cutadapt on the MSU HPCC you can load the module (or a conda environment that you previosuly created that contains cutadapt)
# [benucci@dev-amd20 results]$ module purge
# [benucci@dev-amd20 results]$ module load cutadapt

module purge
module load cutadapt

primer_314F="CCTACGGGAGGCAGCAG"
primer_806R_RC="ATTAGAWACCCBDGTAGTCC"

cutadapt -j 16 -g CCTACGGGAGGCAGCAG -a ATTAGAWACCCBDGTAGTCC -e 0.01 -n 2 --discard-untrimmed --match-read-wildcards -o $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer.fastq $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/noprimer.log

# count reads
sed -n '1~4p' $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer.fastq | awk -F'.' '{print $1}' | sed 's/^@//' | sort | uniq -c > $WORK_DIR/pipeline_USEARCH/stats/4.noprimer.counts

# NOTE. Good idea is to visualize the reads before/after trimming to have a sense where/if the primers are there. 
# use: load the seqtk HPCC module (agian, conda otherwise can be used)
# [benucci@dev-amd20 results]$ module load seqtk

module load seqtk

seqtk sample -s100 $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq 500 > $WORK_DIR/pipeline_USEARCH/results/merged/merged_subset_500.fastq
seqtk seq -aQ64 $WORK_DIR/pipeline_USEARCH/results/merged/merged_subset_500.fastq > $WORK_DIR/pipeline_USEARCH/results/merged/merged_subset_500.fasta

seqtk sample -s100 $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer.fastq 500 > $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer_subset_500.fastq
seqtk seq -aQ64 $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer_subset_500.fastq > $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer_subset_500.fasta

# Download the subset_500.fastq file, I used ondemand but you can use filezilla (my preference) or whatever you want
# Install an alligment tool and viosualize the subset of the reads. 
# I like SeaView becasue is simple and fast https://doua.prabi.fr/software/seaview

# 0.4) valuation of Max Expected Error --------------------------------------#
# reason: identfy max expected errros and decide the optimal lenght form trimming
# This is a step that requires experience! 
# It is always a compromize between quality and number of reads retained.
$USEARCH -fastq_eestats2 $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer.fastq -output $WORK_DIR/pipeline_USEARCH/results/exp_errors/eestats2.res -length_cutoffs 100,500,1

# 0.5) filtering max expected errors ----------------------------------------#
$USEARCH -threads 16 -fastq_filter $WORK_DIR/pipeline_USEARCH/results/noprimer/noprimer.fastq -fastq_maxee 1.00 -fastq_trunclen 400 -fastqout $WORK_DIR/pipeline_USEARCH/results/filtered/filtered.fastq 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/filtered.log

# count readsnts
sed -n '1~4p' $WORK_DIR/pipeline_USEARCH/results/filtered/filtered.fastq | awk -F'.' '{print $1}' | sed 's/^@//' | sort | uniq -c > $WORK_DIR/pipeline_USEARCH/stats/5.filtered.counts

# 0.6) dereplication -----------------------------------------------------------#
# reason: collapse identical sequences 
# NOTE. Sequences are compared letter-by-letter and must be identical over the full length of both sequences (substrings do not match).
$USEARCH -threads 16 -fastx_uniques $WORK_DIR/pipeline_USEARCH/results/filtered/filtered.fastq -fastqout $WORK_DIR/pipeline_USEARCH/results/dereplicated/derep.fastq -fastaout $WORK_DIR/pipeline_USEARCH/results/dereplicated/derep.fasta -sizeout 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/derep.log

# NOTE. You can output both fasta and fastq.

# count reads
sed -n '1~4p' $WORK_DIR/pipeline_USEARCH/results/dereplicated/derep.fastq | awk -F'.' '{print $1}' | sed 's/^@//' | sort | uniq -c > $WORK_DIR/pipeline_USEARCH/stats/6.derep.counts

# 0.7) generating ASVs and asv_table ------------------------------------#
# NOTE. USEARCH uses the unoise algorhithm for this step. 
# NOTE. The -minsize option specifies the minimum abundance (size= annotation). Default is 8.
$USEARCH -unoise3 $WORK_DIR/pipeline_USEARCH/results/dereplicated/derep.fastq -minsize 8 -tabbedout $WORK_DIR/pipeline_USEARCH/results/asvs/asvs.txt -zotus $WORK_DIR/pipeline_USEARCH/results/asvs/asvs.fasta 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/asvs.log

# NOTE. For -otutab usually using sequences immediately after merging (if very noisy then use the filtered sequences but you can inflate your counts) 
$USEARCH -threads 16 -otutab $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq -zotus $WORK_DIR/pipeline_USEARCH/results/asvs/asvs.fasta -otutabout $WORK_DIR/pipeline_USEARCH/results/asvs/asv_table.txt 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/asv_table.log

# 0.8) generating OTUs ------------------------------------------------------#
# >>> Strategy a) - generate OTUs by clustering ASVs
$USEARCH -sortbylength $WORK_DIR/pipeline_USEARCH/results/asvs/asvs.fasta -fastaout $WORK_DIR/pipeline_USEARCH/results/asvs/asvs_sorted.fasta
$USEARCH -cluster_smallmem $WORK_DIR/pipeline_USEARCH/results/asvs/asvs_sorted.fasta -id 0.97 -centroids $WORK_DIR/pipeline_USEARCH/results/asvs/asvs_to97otus.fasta -uc $WORK_DIR/pipeline_USEARCH/results/asvs/asvs_to97otus_clusters.txt 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/asvs_to97otus.log
$USEARCH -threads 16 -otutab $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq -zotus $WORK_DIR/pipeline_USEARCH/results/asvs/asvs_to97otus.fasta -otutabout $WORK_DIR/pipeline_USEARCH/results/asvs/otu_table_asvs_to97otus.txt 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/otutable_asvs_to97otus.log

# >>> Strategy b) - generate OTUs by clustering using the UPARSE algorhitm
# In this case the -minsize option (minimum abundance = size) will impact the presence of singletons OTUs. Default is 1 (this will keep all the singletons), generally if not interested in rare noisy OTUs you should use -minsize 2. 

# NOTE. UPARSE genrates 97% sequence similairty OTUs
$USEARCH -cluster_otus $WORK_DIR/pipeline_USEARCH/results/dereplicated/derep.fastq -minsize 2 -relabel OTU_ -otus $WORK_DIR/pipeline_USEARCH/results/otus/otus_97_UPARSE.fasta -uparseout $WORK_DIR/pipeline_USEARCH/results/otus/otus_97_UPARSE.txt 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/otus_97_UPARSE.log
$USEARCH -threads 16 -otutab $WORK_DIR/pipeline_USEARCH/results/merged/merged.fastq -otus $WORK_DIR/pipeline_USEARCH/results/otus/otus_97_UPARSE.fasta -otutabout $WORK_DIR/pipeline_USEARCH/results/otus/otu_table_97_UPARSE.txt 2>&1 | tee $WORK_DIR/pipeline_USEARCH/logs/otu_table_97_UPARSE.log

# 0.9) Closed reference OTUs -------------------------------------------------------#
# reasons: the idea here is to use a reference that contains the "seeds" for the generated OTUs. This may make sense if we are considering Synthetic communities but this practive is associate with many problems.Please see https://www.drive5.com/usearch/manual/closed_ref_problems.html
# NOTE. 
# * May be usefull for non-overlapping amplicons with the assumption that, for a given species, they will usually be assigned to the same OTU by closed-reference. However the that two non-overlapping amplicons, from the same full-length sequence, will be assigned to the same OTU is only ~30%. 
# * Problems with Valid taxonomy and convergent evolution problmes/mistakes. This happens, for example, when the same genus is in two different families. In greengenes database v.13.8 the genus Flexibacter is placed in three families: Cytophagaceae (OTU 1142767, correct), Flammeovirgaceae (OTU 4447268), and Flavobacteriaceae (OTU 1136639).
# * Problem with asv/otus copies in the same genome. A single strain often contains two or more 16S paralogs, i.e. separate copies of the 16S gene (see 16S copy number). Sometimes these paralogs have different sequences, espeically when there is variation between different strains of the same species. Sometimes two diggrrent genomes may contain the same 16S sequence. This is discussed here: Schloss PD. Amplicon Sequence Variants Artificially Split Bacterial Genomes into Separate Clusters. mSphere. 2021 Aug 25;6(4):e0019121. doi: 10.1128/mSphere.00191-21.
# * May worth testing using a SynCom - discussion open!
$USEARCH -closed_ref $WORK_DIR/pipeline_USEARCH/results/dereplicated/derep.fastq -id 0.97 -db $WORK_DIR/pipeline_USEARCH/closedref_db/closed_ref_seeds.fasta -otutabout $WORK_DIR/pipeline_USEARCH/results/otus/otu_table_closed_ref_97.txt -strand both -tabbedout $WORK_DIR/pipeline_USEARCH/results/otus/otu_table_closed_ref_97_tabbedout.txt

# 10) otu statistics --------------------------------------------------------------#
$USEARCH  -otutab_stats $WORK_DIR/pipeline_USEARCH/results/asvs/asv_table.txt -output $WORK_DIR/pipeline_USEARCH/stats/7.asv_table_report.txt

# 11) Assigning Taxonomy to ASV/OTUs representative seqences ----------------------#
# On V4 reads, using a cutoff of 0.8 gives predictions with similar accuracy to RDP at 80% bootstrap cutoff.
# NOTE. Dwnload reference databases https://www.drive5.com/usearch/manual/sintax_downloads.html
# generate database for use: https://www.drive5.com/usearch/manual/cmd_makeudb_sintax.html
# parameters: https://www.drive5.com/usearch/manual/cmd_sintax.html

# unzip the reference
gunzip -k $WORK_DIR/pipeline_USEARCH/taxonomy_db/*.gz

# generate taxonomy databases
$USEARCH -makeudb_usearch $WORK_DIR/pipeline_USEARCH/taxonomy_db/rdp_16s_v16.fa -output $WORK_DIR/pipeline_USEARCH/taxonomy_db/rdp_16s_v16.udb
$USEARCH -makeudb_usearch $WORK_DIR/pipeline_USEARCH/taxonomy_db/ltp_16s_v123.fa -output $WORK_DIR/pipeline_USEARCH/taxonomy_db/ltp_16s_v123.udb

# assign taxonomy to representative sequences
$USEARCH -sintax $WORK_DIR/pipeline_USEARCH/results/asvs/asvs.fasta -db $WORK_DIR/pipeline_USEARCH/taxonomy_db/rdp_16s_v16.udb -tabbedout $WORK_DIR/pipeline_USEARCH/results/taxonomy_assignments/asvs_rdp.sintax -strand both -sintax_cutoff 0.8 -threads 16

$USEARCH -sintax $WORK_DIR/pipeline_USEARCH/results/asvs/asvs.fasta -db $WORK_DIR/pipeline_USEARCH/taxonomy_db/ltp_16s_v123.udb -tabbedout $WORK_DIR/pipeline_USEARCH/results/taxonomy_assignments/asvs_silva.sintax -strand both -sintax_cutoff 0.8 -threads 16
