#!/bin/bash

input=$1
output=$2
microbiome_genomes=$3


echo "bowtie2 START"
eval "$(micromamba shell hook --shell bash)" ; micromamba activate kneaddata

for fullpath in ${input}/*.fastq.gz; do

	file=$(basename $fullpath)

	# making the name of the compressed files:
        gziped_name=${file/.fastq.gz/.sam.gz} # change ".fastq.gz" to ".sam.gz" in the filename
        # variable with the full path to the output file
        gziped_full_path="${output}/${gziped_name}"

	echo "Analysing sample: $file"

        # run bowtie with paited runs
        bowtie2 -p 60 -x ${microbiome_genomes} -U ${fullpath} --very-sensitive --no-unal --seed 1021997 | cut -f1-9 | sed 's/$/ * */' | gzip > ${gziped_full_path}

done

micromamba deactivate
echo "bowtie2 FINISHED"

