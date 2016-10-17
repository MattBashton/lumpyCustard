#!/bin/bash -eu
#$ -cwd -V
#$ -pe smp 10
#$ -l h_rt=24:00:00
#$ -l h_vmem=70G
#$ -R y
#$ -q all.q,bigmem.q

# Matthew Bashton 2015-2016
# Runs Ensembl VEP this needs modules for VEP since it has a lot of
# dependancies which are not trivial to install.

# Using local cache copied from that installed to luster FS via head node as
# multiple jobs all writing to same files may cause issues, also cache works
# by streaming zcat of .gz files so rather suboptimal for cluster.

module add apps/perl
module add apps/samtools/1.3.1
module add apps/VEP/v86

set -o pipefail
hostname
date

source ../lumpySettings.sh

SAMP_ID=$(awk "NR==$SGE_TASK_ID" ../master_list.txt | perl -ne '/SM:(\S+)\\t/; print "$1\n"')

echo "** Variables **"
echo " - BASE_DIR = $BASE_DIR"
echo " - SAMP_ID = $SAMP_ID"
echo " - PWD = $PWD"

echo "Copying input $BASE_DIR/lumpyexpress/$SAMP_ID.vcf to $TMPDIR/"
/usr/bin/time --verbose cp -v  $BASE_DIR/lumpyexpress/$SAMP_ID.vcf $TMPDIR

echo "Creating VEP cache dirs on local scratch in $TMPDIR"
# Note just using 86_GRCh37 this will need to change from release to release  / organism / reference
mkdir $TMPDIR/vep_cache

echo "Copying VEP cache: $GLOBAL_VEP_CACHE to $TMPDIR/vep_cache"
/usr/bin/time --verbose cp -R $GLOBAL_VEP_CACHE/homo_sapiens $TMPDIR/vep_cache/
/usr/bin/time --verbose cp -R $GLOBAL_VEP_CACHE/Plugins $TMPDIR/vep_cache/

echo "Setting VEP cache location to $TMPDIR/vep_cache"
VEP_CACHEDIR="$TMPDIR/vep_cache"

# Not needed for b37
#echo "Converting $B_NAME.vcf to ensembl chr ids using sed"
#sed -i.bak s/chr//g $TMPDIR/$B_NAME.vcf

echo "Running VEP on $TMPDIR/$SAMP_ID.vcf"
/usr/bin/time --verbose variant_effect_predictor.pl \
--format vcf \
-i $TMPDIR/$SAMP_ID.vcf \
--no_progress \
--cache \
--port 3337 \
--everything \
--force_overwrite \
--maf_exac \
--html \
--tab \
-o $TMPDIR/$SAMP_ID.txt \
--dir $TMPDIR/vep_cache/ \
--buffer_size 25000 \
--fork 10 \
--pick_allele

echo "Copying back VEP *.txt output from $TMPDIR to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*.txt $PWD

echo "Copying back VEP *.html output from $TMPDIR to $PWD"
/usr/bin/time --verbose cp -v $TMPDIR/*.html $PWD

# Cleaning up
echo "Removing *.txt *.html *.vcf from $TMPDIR"
rm $TMPDIR/*.txt
rm $TMPDIR/*.html
rm $TMPDIR/*.vcf

date

# Used by Audit_run.sh for calculating run length of whole analysis
ENDTIME=`date '+%s'`
echo "Timestamp $ENDTIME"

echo "END"
