#!/bin/bash --login
#SBATCH --time=3:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=6
#SBATCH --mem-per-cpu=8G
#SBATCH --job-name classifier

cd /mnt/scratch/yangjinn/16SAmpliconWorkshop

module purge
module load Miniforge3
conda activate qiime2-2024.10

qiime feature-classifier extract-reads \
  --i-sequences silva-138-99-seqs.qza \
  --p-f-primer CCTACGGGNGGCWGCAG \
  --p-r-primer GGACTACHVGGGTATCTAAT \
  --p-trunc-len 470 \
  --p-min-length 200 \
  --p-max-length 500 \
  --o-reads ref-seqs-341-806.qza

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs-341-806.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier classifier-341-806.qza

