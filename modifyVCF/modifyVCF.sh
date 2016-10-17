#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 1
#$ -l h_rt=2:00:00
#$ -l h_vmem=1G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2016
# Takes lumpy express VCF and expands out genotype field to tab delimited text

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

echo "Copying input $BASE_DIR/lumpyexpress/$SAMP_ID.vcf to $TMPDIR"
/usr/bin/time --verbose cp -v $BASE_DIR/lumpyexpress/$SAMP_ID.vcf $TMPDIR

echo "Running awk on $TMPDIR/$SAMP_ID.vcf saving reprocessed output to $SAMP_ID.txt"
cd $TMPDIR
/usr/bin/time --verbose awk -F '\t' -v OFS='\t' 'FNR > 32 {$10=gensub(/:/,"\t","g",$10);print $1,$2,$3,$4,$5,$6,$7,$8,$10}' $SAMP_ID.vcf > $SAMP_ID.txt
cd $DEST

echo "Copying back output text file $TMPDIR/$SAMP_ID.txt to $DEST"
/usr/bin/time --verbose cp -v $TMPDIR/$SAMP_ID.txt $DEST

echo "Deleting $TMPDIR/$SAMP_ID.*"
rm $TMPDIR/$SAMP_ID.*

date
echo "END"
