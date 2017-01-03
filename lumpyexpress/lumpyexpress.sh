#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 2
#$ -l h_rt=480:00:00
#$ -l h_vmem=10G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2012-2016
# Runs lumpy express
# Job time being used too to help with getting a slot, 48hrs set - alter if need be.
# Can optionally remove .sam from BWA_MEM dir to clean up.

set -o pipefail
hostname
date

source ../lumpySettings.sh

SAMP_ID=$(awk "NR==$SGE_TASK_ID" ../master_list.txt | perl -ne '/SM:(\S+)\\t/; print "$1\n"')
DEST=$PWD

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - SAMP_ID = $SAMP_ID"
echo " - PWD = $PWD"
echo " - DEST = $DEST"
echo " - REF = $REF"

echo "Copying input $BASE_DIR/SamToSortedBam/$SAMP_ID.ba* to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/SamToSortedBam/$SAMP_ID.bam $TMPDIR
/usr/bin/time --verbose cp -v $BASE_DIR/SamToSortedBam/$SAMP_ID.bai $TMPDIR

echo "Running lumpyexpress on input bam $TMPDIR/$SAMP_ID.bam"
cd $TMPDIR
/usr/bin/time --verbose $LUMPYEXPRESS -v -k -B $SAMP_ID.bam -o $SAMP_ID.vcf -T $TMPDIR/LUMPYtmp.$SAMP_ID
cd $DEST

echo "Copying back output VCF $TMPDIR/$SAMP_ID.vcf to $DEST"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.vcf $DEST

echo "Deleting $TMPDIR/$SAMP_ID.*"
rm $TMPDIR/$SAMP_ID.*

date
echo "END"
