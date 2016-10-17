#!/bin/bash -e

# Matthew Bashton 2016

# A script of common lumpyCustard settings file, this file gets sourced by the 
# various scripts in the subdirs up a level from this base dir.  This allows for
# different runs to have different settings rather than a global file in users
# home dir.

## Base dir - should auto set to where this script resides
BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## Master list for the whole run, which has as tab-delimited text for each
# sample: ID, @RG line, R1.fastq, R2.fastq (assumption is reads are paired)
MASTER_LIST="$BASE_DIR/master_list.txt"

## Global job name
# This gets appended to the job name for each stage so you can track multiple
# different runs in qstat.  Change this for each run so they don't clash.
G_NAME="custard"

# Ensure file creation is private to prevent temp files and other data being
# accessed by others
umask 077

## We need latest GCC libs (FMS cluster specific)
module add compilers/gnu/4.9.3
## We also need a current version of python
module add apps/python27/2.7.8
## Note that VEP is loaded by a module add in the VEP.sh script
##  Add in module for Java 1.8 (FMS cluster specific)
module add apps/java/jre-1.8.0_92

# Python dependencies should be PIP install --user <package name> installed to 
# home dir, these are: pysam (0.8.3+) and NumPy (1.8.1+).  Also note that 
# lumpyexpress will require Samtools and SAMBLASTER, the locations of which 
# need to be defined in LUMPY's lumpyexpress.config.

## Location of programs
FASTQC="/opt/software/bsu/bin/fastqc"
BWA="/opt/software/bsu/bin/bwa"
JAVA="/opt/software/java/jdk1.8.0_92/bin/java -XX:-UseLargePages -Djava.io.tmpdir=$TMPDIR"
PICARD="/opt/software/bsu/bin/picard.jar"
LUMPY="/opt/software/bsu/bin/lumpy"
LUMPYEXPRESS="/opt/software/bsu/bin/lumpyexpress"

## Ensembl VEP cache location, note to improve performance this will be copied
# to $TMPDIR on the start of each VEP job.
GLOBAL_VEP_CACHE="/opt/databases/ensembl-tools/ensembl-tools-86/VEP"

## GATK bundel dir, I use the referance genomes from here:
BUNDLE_DIR="/opt/databases/GATK_bundle/2.8/b37"
REF="$BUNDLE_DIR/human_g1k_v37.fasta"
