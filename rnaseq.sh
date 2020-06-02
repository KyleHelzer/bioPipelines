#!/bin/bash

# Author: Kyle Helzer
# email: helzerk@gmail.com

# programs needed in PATH:
# prefetch (sratoolkit)
# fasterq-dump (sratoolkit)
# hisat2
# samtools
# stringtie

# TODO take in command line inputs as flags for:
		# genome index
		# genome gtf file
		# number of processors
# TODO incorporate fastqc in pipeline
# TODO have script remove _1.fastq and _2.fastq after alignment and conversion to BAM
# TODO ?? delete unneeded files after analysis to save disk space?? Could gzip, but adds additional time
# TODO use WHICH to check if programs are in PATH. If not, throw error and exit
# TODO use SECONDS to calculate time
# TODO write timing out to file with input file sizes too

# Download SRR file with prefetch
# move or access files in SRAdeposit folder?

STARTTIME=$(date +"%T")

# Extract sequences with fasterq-dump
echo [$(date +"%T")] Dumping fastq files;
for FILE in *.sra;
do
	echo [$(date +"%T")] dumping $FILE;
	fasterq-dump $FILE -e 2;
	echo [$(date +"%T")] finished dumping $FILE;
done

printf "\n";

# Align with HISAT2
INDEXPATH="/home/kyle/genomes/Homo_sapiens/hg38/hg38_tran/genome_tran";
echo [$(date +"%T")] Aligning to $INDEXPATH with HISAT2;
for FILE in *.sra_1.fastq;
do
	PREFIX="${FILE%.sra_1.fastq}";
	echo [$(date +"%T")] aligning $PREFIX;
	FILE1=$FILE;
	FILE2="${FILE%1.fastq}2.fastq";
	hisat2 -p 2 --dta -x $INDEXPATH -1 $FILE1 -2 $FILE2 -S $PREFIX.sam;
	echo [$(date +"%T")] finished alignment of $PREFIX;
	echo [$(date +"%T")] Converting SAM to BAM and sorting $FILE;
	samtools sort -@ 2 -o $PREFIX.bam $PREFIX.sam;
	rm $PREFIX.sam; # removes large SAM file
	echo [$(date +"%T")] Done;
done

printf "\n";

# Convert SAM to BAM and sort
# echo [$(date +"%T")] Converting SAM to BAM and sorting;
# for FILE in *.sam;
# do
	# echo [$(date +"%T")] Converting and sorting $FILE;
	# PREFIX="${FILE%.sam}";
	# samtools sort -@ 2 -o $PREFIX.bam $FILE;
	# rm $FILE; # removes large SAM file
	# echo [$(date +"%T")] Done;
# done

printf "\n";

# Get expression estimates with Stringtie
echo [$(date +"%T")] Calculating expression estimates with Stringtie;
OUTDIR=bgfiles_$(date +%Y%m%d_%H%M%S);
mkdir $OUTDIR;
GTFPATH="/home/kyle/genomes/Homo_sapiens/hg38/hg38_tran/hg38_ucsc.annotated.gtf";
for FILE in *.bam;
do
	echo [$(date +"%T")] Analyzing $FILE;
	PREFIX="${FILE%.bam}";
	mkdir $PREFIX;
	stringtie -p 2 -G $GTFPATH -e -B -o $PREFIX/transcripts.gtf -A $PREFIX/gene_abundances.tsv $FILE;
	mv $PREFIX/ $OUTDIR/;
	echo [$(date +"%T")] Done;
done

printf "\n";

ENDTIME=$(date +"%T")
echo Start $STARTTIME;
echo End $ENDTIME
