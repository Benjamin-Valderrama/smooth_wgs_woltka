#!/bin/bash

# Default values

current_wd="`pwd`"
study_folder=""

run_all=false
run_download=false
run_bowtie=false
run_woltka=false
run_modules=false

accession_number=""
library_layout="PE"
host_genome=""
microbiome_genomes=""


# Function to display script usage
function display_usage() {
    echo "Usage: $0 -s|--study_folder STUDY_FOLDER [-r|--run_all] [-n|--accession_number ACCESSION_NUMBER]"
    echo "	[--run_download] [--run_kneaddata] [--run_woltka] [--run_modules] [-h|--help]"
    echo ""
    echo "Required arguemnts:"
    echo "  -s, --study_folder       Specify the name of the folder of the study to analyse"
    echo ""
    echo "Workflow arguments:"
    echo "  -r, --run_all            Run all steps of the workflow."
    echo "  --run_download           Run data download [uses fastq-dl]."
    echo "  --run_kneaddata          Run reads quality check and alignment [uses kneaddata]."
    echo "  --run_woltka             Run taxonomic and functional profilling [uses woltka]."
    echo "  --run_modules            Run module abundance and coverage calculation [uses OmixerRpm in R]."
    echo ""
    echo "Optional arguments:"
    echo "  -n, --accession_number   Specify the accession number of the raw data at the ENA (Needed if --run_all or --run_download are used)."
    echo "  --library_layout         PE/SE for paired end or single end, respectively [default: PE] (Needed if --run_kneaddata is used)."
    echo "  --host_genome            Path to folder with bowtie2 index of host genome (Needed if --run_kneaddata is used)."
    echo "  --microbiome_genomes     Path to folder with bowtie2 index of the microbiome ending with index prefix [path/to/folder/index-prefix] (Needed if --run_kneaddata is used)."
    echo "  -h, --help               Display this help message."
    echo ""
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -s|--study_folder)
            study_folder="$2"
            shift
            shift
            ;;
	--library_layout)
	    library_layout="$2"
	    shift
            shift
	    ;;
        --host_genome)
            host_genome="$2"
            shift
            shift
            ;;
        --microbiome_genomes)
            microbiome_genomes="$2"
            shift
            shift
            ;;
        -r|--run_all)
            run_all=true
            shift
            ;;
        -n|--accession_number)
            accession_number="$2"
            shift
            shift
            ;;
        --run_download)
            run_download=true
            shift
            ;;
        --run_kneaddata)
            run_kneaddata=true
            shift
            ;;
        --run_woltka)
            run_woltka=true
            shift
            ;;
        --run_modules)
            run_modules=true
            shift
            ;;
        -h|--help)
            display_usage
            ;;
        *)
            echo "Unknown option: $1"
            display_usage
            ;;
    esac
done

# Check if required flag is provided
if [ -z "$study_folder" ]; then
    echo "Study folder is required."
    display_usage
fi


# 0. setting up the study folder (used when raw data is not downloaded from ENA)
if [ ! -d ${study_folder} ]; then
	echo "PROGRESS -- Creating study folder : ${study_folder}"

	mkdir ${study_folder}
	mkdir ${study_folder}/00.rawdata
	mkdir ${study_folder}/nohups
else
	echo "PROGRESS -- The folder '${study_folder}' already exists. Moving to the next step ..."
fi


# 1. fastq-dl: download data from ENA.
if [ "$run_all" = true ] || [ "$run_download" = true ]; then
    if [ -z "$accession_number" ]; then
        echo "Accession number is required for downloading raw data."
        exit 1
    fi

    # DOWNLOAD DATA
    echo "PROGRESS -- Download raw data from ENA. Project accession number : ${accession_number}."
    bash /home/bvalderrama/scripts/woltka_wgs/fastqdl.sh "${current_wd}/${study_folder}" "${accession_number}" &> "${study_folder}/nohups/download.out"
fi


# 2. kneaddata & bowtie2: quality check, filter, trim and alignment to microbiome and host genomes.
if [ "$run_all" = true ] || [ "$run_kneaddata" = true ]; then
    mkdir ${study_folder}/01.cleandata
    mkdir ${study_folder}/01.cleandata/host
    mkdir ${study_folder}/01.cleandata/non-host
    mkdir ${study_folder}/01.cleandata/other_outputs
    mkdir ${study_folder}/01.cleandata/microbiome

    if [ "$library_layout" != "PE" ] && [ "$library_layout" != "SE" ]; then
	echo "--library_layout should be either 'PE' or 'SE'"
	display_usage
    fi

    if [ -z host_genome ] || [ -z microbiome_genomes ]; then
	echo "Path to host genome and microbiome genomes indices are required"
	display_usage
    fi

	if [ "$library_layout" = "PE" ]; then
	    # run kneaddata
	    echo "PROGRESS -- Filter and trim of paired end raw sequences. Remove reads aligning to host genome."
	    bash /home/bvalderrama/scripts/woltka_wgs/kneaddata.sh ${current_wd}/${study_folder}/00.rawdata ${current_wd}/${study_folder}/01.cleandata $host_genome&> "${study_folder}/nohups/kneaddata.out"
	    # run bowtie2
	    echo "PROGRESS -- Alignment of paired end sequences to microbiome genomes."
	    bash /home/bvalderrama/scripts/woltka_wgs/bowtie2.sh ${current_wd}/${study_folder}/01.cleandata/non-host ${current_wd}/${study_folder}/01.cleandata/microbiome $microbiome_genomes &> "${study_folder}/nohups/bowtie2.out"


	elif [ "$library_layout" = "SE" ]; then
	    # run single end kneaddata
            echo "PROGRESS -- Filter and trim of single end raw sequences. Remove reads aligning to host genome."
	    bash /home/bvalderrama/scripts/woltka_wgs/singleend_kneaddata.sh ${current_wd}/${study_folder}/00.rawdata ${current_wd}/${study_folder}/01.cleandata $host_genomes &> "${study_folder}/nohups/kneaddata.out"
	    # run single end bowtie2
            echo "PROGRESS -- Alignment of single end sequences to microbiome genomes."
	    bash /home/bvalderrama/scripts/woltka_wgs/singleend_bowtie2.sh ${current_wd}/${study_folder}/01.cleandata/non-host ${current_wd}/${study_folder}/01.cleandata/microbiome $microbiome_genomes &> "${study_folder}/nohups/bowtie2.out"
	fi
fi


# 3. woltka: taxonmic and functional annotations using close-reference database
if [ "$run_all" = true ] || [ "$run_woltka" = true ]; then
    # RUN WOLTKA TO ANNOTATE THE SAMPLES USING THE ALIGNMENTS PRODUCED IN THE PREVIOUS STEP
    echo "PROGRESS -- Performing taxonomic and functional profiling (KO-based)."
    mkdir ${study_folder}/02.annotations
    mkdir ${study_folder}/02.annotations/taxonomy
    mkdir ${study_folder}/02.annotations/functional

    bash /home/bvalderrama/scripts/woltka_wgs/woltka.sh ${study_folder}/01.cleandata/microbiome ${study_folder}/02.annotations &> "${study_folder}/nohups/woltka.out"
fi


# 4. OmixerRpm: calculate modules
if [ "$run_all" = true ] || [ "$run_modules" = true ]; then
    # CALCULATE THE GBMs USING THE FUNCTIONAL ANNOTATION GENERATED ABOVE
    echo "PROGRESS -- Calculating modules (from KO-based functional profile)."
    mkdir ${study_folder}/03.modules

    bash /home/bvalderrama/scripts/woltka_wgs/run_modules.sh ${current_wd}/${study_folder}/02.annotations/functional ${current_wd}/${study_folder}/03.modules -m GBMs,GMMs &> "${study_folder}/nohups/omixer.out"
fi

echo "PROGRESS -- WGS primary analysis finished."
