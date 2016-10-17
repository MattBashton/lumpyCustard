#!/bin/bash -e
# Matthew Bashton 2016

# Runs BWA MEM, lumpyexpress and VEP also reformats VCF output GT field from
# LUMPY to tab delimited.

tput bold
echo "Matt Basthon 2016"
echo -e "Running lumpyCustard pipeline\n"
tput sgr0

set -o pipefail

tput setaf 1
hostname
date
# Used by Audit_run.sh for calculating run length of whole analysis
date '+%s' > start.time
echo ""
tput sgr0

# Load settings for this run
source lumpySettings.sh

tput setaf 2
echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - G_NAME = $G_NAME"
echo " - MASTER_LIST = $MASTER_LIST"
echo " - PWD = $PWD"

# Determine number of samples in master list
N=$(wc -l $MASTER_LIST | cut -d ' ' -f 1)
echo -e " - No of samples = $N\n"
tput sgr0

#### QC
tput bold
echo " * 1 FastQC Jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.FastQC -wd $PWD/FastQC FastQC/FastQC.sh

#### Alignment
tput bold
echo " * 1 BWA jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.BWA -wd $PWD/BWA_MEM BWA_MEM/BWA.sh

#### Convert SAM to BAM and save by sample ID
tput bold
echo " * 3 SortSam jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.SamToSortedBam -hold_jid_ad $G_NAME.BWA -wd $PWD/SamToSortedBam SamToSortedBam/SamToSortedBam.sh

#### lumpyexpress
tput bold
echo " * 2 lumpyexpress jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.lumpyexpress -hold_jid_ad $G_NAME.SamToSortedSam -wd $PWD/lumpyexpress lumpyexpress/lumpyexpress.sh

#### Ensembl VEP
tput bold
echo " * 3 Ensembl VEP jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.VEP -hold_jid $G_NAME.lumpyexpress -wd $PWD/VEP $PWD/VEP/VEP.sh

#### Reprocess VCF to txt expanding genotype field
tput bold
echo " * 4 awk jobs submitted"
tput sgr0
qsub -t 1-$N -N $G_NAME.modifyVCF -hold_jid $G_NAME.lumpyexpress -wd $PWD/modifyVCF $PWD/modifyVCF/modifyVCF.sh

echo ""
tput setaf 2
# Cowsay is optional!
cowsay "All jobs submitted"
#echo -e "All jobs submitted\n\n"
tput sgr0
