#!/bin/bash

input=$1
output=$2
microbiome_genomes=$3

echo "bowtie2 START"
eval "$(micromamba shell hook --shell bash)" ; micromamba activate kneaddata

for f1 in ${input}/*_1.fastq.gz; do

	# making the name of the reverse reads
        f2=${f1/_1/_2}

        # making the name of the compressed files:
        f1_name="${f1##*/}" # keeping only the name of the forward read
        gziped_name=${f1_name/_1.fastq.gz/.sam.gz} # change "_1.fastq.gz" to ".sam.gz" in the filename

        # variable with the full path to the output file
        gziped_full_path="${output}/${gziped_name}"

	echo "Analysing sample: ${f1_name/_paired_1.fastq.gz/}"

        # run bowtie with paited runs
        bowtie2 -p 60 -x ${microbiome_genomes} -1 ${f1} -2 ${f2} --very-sensitive --no-unal --seed 1021997 | cut -f1-9 | sed 's/$/ * */' | gzip > ${gziped_full_path}
done

micromamba deactivate
echo "bowtie2 FINISHED"

