# lumpyCustard #

## LUMPY structural variant detection pipeline using SGE ##

## Overview ##
This is a sets of scripts for running [LUMPY Express](https://github.com/arq5x/lumpy-sv) on an SGE based cluster (specifically I've tested them using [Son of Grid Engine](https://arc.liv.ac.uk/trac/SGE)).  [BWA MEM](http://bio-bwa.sourceforge.net/) is used to align FASTQ, followed by conversion to sorted BAM with [Picard](http://broadinstitute.github.io/picard/).  LUMPY express is then run, followed by structural variant annotation with [Ensembl VEP](http://www.ensembl.org/info/docs/tools/vep/script/vep_download.html) LUMPYs output VCF also has it's genotype fields split from `:` separated to tab-delimited `\t` which makes reading the output VCF file and sorting via the number of supporting reads columns much easier (see original VCF header for details).  [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) is also run as a Quality Control step on input FASTQ. 

### Instructions ###
The pipeline requires some settings namely `$G_NAME` which is a global name for an analysis run which needs to be set in the `lumpySettings.sh` file.  The automated pipeline is run using SGE array job dependancies such that should say the BWA stage for a sample complete the corresponding SamToSortedBam stage for said sample will launch in the next job array and so on.  The file `instantCustard.sh` specifies the pipeline as a series of qsub commands.  Finally a file called `master_list.txt` needs to be present in the same dir as `lumpySettings.sh` / `instantCustard.sh` this is a tab-delimited flat file, which encodes per-line numeric sample id, the `@RG` read group definition line for BWA to incorporate into SAM headers, and the locations of each pair of FASTQ files for BWA for that sample one after the other, these need to be referenced as `../FASTQ/<name_1>.fastq.gz` and `../FASTQ/<name_2>.fastq.gz` as these paths are being passed to BWA operating out of the `BWA_MEM/` dir, the two files needs to be separated by a tab character as do all the other fields.  The format of the file should look like this:

```
1       @RG\tID:RG_01\tLB:Lib_01\tSM:Sample_01\tPL:ILLUMINA       ../FASTQ/Sample_01_1.fastq.gz        ../FASTQ/Sample_01_2.fastq.gz
2       @RG\tID:RG_02\tLB:Lib_02\tSM:Sample_02\tPL:ILLUMINA       ../FASTQ/Sample_02_1.fastq.gz        ../FASTQ/Sample_02_2.fastq.gz
3       @RG\tID:RG_03\tLB:Lib_03\tSM:Sample_03\tPL:ILLUMINA       ../FASTQ/Sample_03_1.fastq.gz        ../FASTQ/Sample_03_2.fastq.gz
```

Note that the `\t` present in the second column (which will define the read groups in your SAM headers) is present to indicate to BWA that this should be a tab character as these can't be directly passed to BWA on the command-line.  Not that LUMPY express and this pipe-line will both assume that only one sample is present (with one read group) per BAM file.

## Dependancies ##
The following binaries and resources are required:

* [LUMPY](https://github.com/arq5x/lumpy-sv)
* [Burrows-Wheeler Aligner](http://bio-bwa.sourceforge.net/)
* [Picard tools](http://broadinstitute.github.io/picard/)
* [GATK Resource Bundle 2.8](https://www.broadinstitute.org/gatk/download/)
* [Son of Grid Engine](https://arc.liv.ac.uk/trac/SGE)
* [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
* [Ensembl Variant Effect Predictor](http://www.ensembl.org/info/docs/tools/vep/script/vep_download.html)
* [Cowsay](https://en.wikipedia.org/wiki/Cowsay) optional :)

## Performance optimisations ##
Where possible throughout the pipeline/workflow parallelisation and SGE job memory allocation is appropriately set for maximum performance without wastage.

The output of BWA is not piped via the shell into Picard SortSam as this appears to limit BWAs performance to a single thread.  Bam indexes `.bai` are created on the fly for all stages where required using `CREATE_INDEX=true` in Picard tools this saves time reading in the file a second time for indexing as a separate stage.

The execution of all stages is monitored using GNU time (in verbose mode) this reports CPU and memory usage (beware the four fold memory over reporting [issue](https://groups.google.com/forum/#!topic/gnu.utils.help/u1MOsHL4bhg) on older distributions with unpatched code).  

### IO optimisation for Lustre FS ###
The cluster environment used in testing uses the [Lustre (file system)](http://lustre.org/), this is very efficient at large monolithic file transfers but slow at successive small read/write operations used by many bioinformatics programs.  Each job thus copies the input to local scratch (created under $TMPDIR by SGE) as local disk proves to be faster in all cases, copying was fast on test hardware owing to 40GbE networking.  At the end of each analysis run the output files are copied back of local scratch to Lustre, this reduces load on Lustre too and is likely to be beneficial for systems running NFS as well, as multiple simulations and successive small read/write operations can also degrade performance and swamp the network/NFS daemon.

## Error tracking and debugging ##
All bash scripts run with `bash -e`, and will thus bail on any error, `set -o pipefail` is also used ensuring failures in piping operations also result in a script stopping.  All copy operations and runs of any binary or GATK are done with `/usr/bin/time -—verbose` preceding them, this means that GNU time will log time, memory, CPU usage and IO.  This is useful not just in profiling the performance and run time of a job, but also to log the exit code too, this output will be sent to standard error when whatever was being timed finishes.  Currently both standard error and out are directed to separate files.  LUMPY and BWA along with other programs and GNU time will write to standard error.  Each script logs the time/date and hostname at the start of execution along with a list of all variables used in the run to standard out when initialised to help with debugging, so separating this from GATK output helps with quickly establishing what is going on.  The final line of each script if run correctly will always be `END`.  Consequently you can check to see if all scripts of a particular stage have run correctly using:

`grep -c END *.o*`

in each directory, scripts that ran successfully will have a count of 1 those which failed will be 0.

Only scripts that ran fully without error will have their last line as `END` on their standard out.  Non-zero exit status can be checked for in all scripts via:

`grep Exit *.e*`

anything non-zero here indicates that a copy operation or LUMPY / BWA or other binary terminated abnormally.

### What happens if a stage or individual job fails in the automated pipeline? ###
Presently SGE will blindly run the next stage of the job array dependency chain.  However, this not as bad as it seems since `bash -e` is employed at the start of each script, should the main binary for a preceding job fail, the final copy operation from `$TMPDIR` will never run.  Consequently upon starting the next stage of the automated pipeline will fail to find it's input file immediately and terminate.  Should this happen, the failing job and downstream jobs can be re-run using array job notation, this is set at `-t 1-$N` by default, simply change this to `-t n`, where `n `is the array job(s) that failed, commas can by used to specify additional tasks of the array job.  I plan to improve this behaviour in future updates.


