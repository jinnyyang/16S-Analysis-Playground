#!/bin/bash --login
#SBATCH --time=3:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=64G
#SBATCH --job-name cutadapt_Qiime2_DADA2_blastn

######################################
######### cutadapt #######
module purge
module load cutadapt

mkdir -p cutadapt_out

for r1 in RawSeq/*_L001_R1_001.fastq.gz; do
  sample=$(basename "$r1" _L001_R1_001.fastq.gz)
  cutadapt \
    -g CCTACGGGNGGCWGCAG \
    -G GGACTACHVGGGTATCTAAT \
    -o cutadapt_out/${sample}_L001_R1_001.fastq.gz \
    -p cutadapt_out/${sample}_L001_R2_001.fastq.gz \
   RawSeq/${sample}_L001_R1_001.fastq.gz RawSeq/${sample}_L001_R2_001.fastq.gz
done

######### QIIME2 x DADA2 #######
module purge
module load Miniforge3
conda activate qiime2-2024.10

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path cutadapt_out \
  --output-path paired-end-demux.qza \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt

qiime demux summarize \
  --i-data paired-end-demux.qza \
  --o-visualization paired-end-demux.qzv

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs paired-end-demux.qza \
  --p-trim-left-f 0 \
  --p-trim-left-r 0 \
  --p-trunc-len-f 230 \
  --p-trunc-len-r 230 \
  --o-table feature-table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza

qiime feature-table summarize \
  --i-table feature-table.qza \
  --o-visualization feature-table.qzv 

mkdir -p export

qiime tools export \
  --input-path feature-table.qza \
  --output-path feature-table_biom

biom convert \
  -i feature-table_biom/feature-table.biom \
  -o export/feature-table.tsv \
  --to-tsv

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

qiime feature-classifier classify-sklearn \
  --i-classifier classifier-341-806.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

qiime tools export \
  --input-path taxonomy.qza \
  --output-path export

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

qiime tools export \
  --input-path rooted-tree.qza \
  --output-path export

##### Matching amplicon and Sanger sequencing with blastn ########

echo -e "feature-id\nSCR1\nSCR2\nSCR3" > InitialSynComName.txt

qiime feature-table filter-samples \  --i-table feature-table.qza \  --m-metadata-file InitialSynComName.txt \  --o-filtered-table SynComOnly_feature-table.qza

qiime tools export \
  --input-path SynComOnly_feature-table.qza \
  --output-path SynComOnly_feature-table_biom

biom convert \
  -i SynComOnly_feature-table_biom/feature-table.biom \
  -o SynComOnly_feature-table.tsv \
  --to-tsv

{ 
  echo -e "feature-id";
  awk 'NR>2 {print $1}' SynComOnly_feature-table.tsv
} > SynComASVName.txt

qiime feature-table filter-seqs \
  --i-data rep-seqs.qza \
  --m-metadata-file SynComASVName.txt \
  --o-filtered-data SynCom-rep-seqs.qza

qiime tools export \
  --input-path SynCom-rep-seqs.qza \
  --output-path SynCom_exported-seqs

module load BLAST+

makeblastdb -in SynComSanger.csv -dbtype nucl -out SymCom_db

blastn -query SynCom_exported-seqs/dna-sequences.fasta \
  -db SymCom_db \
  -perc_identity 97 \
  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" \
  -out export/SynComASV_results_97.txt

header="ASVID	SynComID	pident	length	mismatch	gapopen	qstart	qend	sstart	send	evalue	bitscore"
sed -i "1i$header" export/SynComASV_results_97.txt

