## Smooth analysis

Here I share scripts I made for the analysis of microbiome data. The scripts allows the user to perform (any of) the following tasks: 
* (1) Data adquisition : [fastq-dl](https://github.com/rpetit3/fastq-dl) is used to download fastq files from ENA
* (2) Data quality control and host decontamination : [kneaddata](https://github.com/biobakery/kneaddata) is used
* (3) Alignment of microbiome DNA to reference db : [bowtie2](https://github.com/BenLangmead/bowtie) is used to generate the sequences alignment. Woltka's default db is used as a reference.
* (4) Community profiling : [Woltka](https://github.com/qiyunzhu/woltka) is used to generate the taxonomic and functional profile of the microbiome.
* (5) Pathways annotation : [OmixerRpm](https://github.com/omixer/omixer-rpmR) (R package) is used to generate annotation of GBMs, pathways involved in the synthesis and degradation of neuroactive compounds.

## Requirements

The scipts assume micromamba is used to manage different software and the following environments are available to the user:

* (1) fastq-dl
* (2) kneaddata
* (3) woltka

The environments can be created from the files provided in the `envs` folder as follows:
```CODE```

## Usage

We look at the help message of the software
```
Study folder is required.
Usage: wgs_smooth_woltka.sh -s|--study_folder STUDY_FOLDER [-r|--run_all] [-n|--accession_number ACCESSION_NUMBER]
        [--run_download] [--run_kneaddata] [--run_woltka] [--run_modules] [-h|--help]

Required arguemnts:
  -s, --study_folder       Specify the name of the folder of the study to analyse

Workflow arguments:
  -r, --run_all            Run all steps of the workflow.
  --run_download           Run data download [uses fastq-dl].
  --run_kneaddata          Run reads quality check and alignment [uses kneaddata].
  --run_woltka             Run taxonomic and functional profilling [uses woltka].
  --run_modules            Run module abundance and coverage calculation [uses OmixerRpm in R].

Optional arguments:
  -n, --accession_number   Specify the accession number of the raw data at the ENA (Needed if --run_all or --run_download are used).
  --library_layout         PE/SE for paired end or single end, respectively [default: PE] (Needed if --run_kneaddata is used).
  --host_genome            Path to folder with bowtie2 index of host genome (Needed if --run_kneaddata is used).
  --microbiome_genomes     Path to folder with bowtie2 index of the microbiome ending with index prefix [path/to/folder/index-prefix] (Needed if --run_kneaddata is use>
  -h, --help               Display this help message.
```

### Run the full workflow

We could easily run the analysis of the microbiome dataset used in this [paper](https://www.nature.com/articles/s41564-018-0306-4), which was made publicly available in ENA under the accession code [PRJNA400072](https://www.ebi.ac.uk/ena/browser/view/PRJNA400072) by running the following line of code
```
nohup bash wgs_smooth_woltka.sh -s franzosa2018 -n PRJNA400072 --run_all --host_genome path/to/host-genome/ --microbiome_genomes path/to/microbiome-genomes/index-prefix > run_all.log &
```
Notice that the path to the indices should be change according to the needs of the user. Additionally, this the project we are working with characterised the gut microbiome of healthy individuals and IBD patients. Therefore, the host genome used to decontaminate the fastq files is a human genome. Many versions of the human genome are available, but I personally use [CHM13v2.0](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_009914755.1/), which is a telomer-to-telomer sequenciation of the human genome. After downloading the genome an index should be built, which can be done by bowtie2. Regarding the microbiome genomes, it is also an index of any microbiome genomes. As recommended by Woltka's developers, it could be the [WoL](https://biocore.github.io/wol/) but it could also be any other more up-to-date index

### Run sections of the workflow

If we already have fastq files, we could run the analysis from an existing directory

```
nohup bash wgs_smooth_woltka.sh -s franzosa2018 --run_kneaddata --run_woltka --run_modules --host_genome path/to/host-genome/ --microbiome_genomes path/to/microbiome-genomes/index-prefix > analysis.log &
```

Each step described in the 'Smooth analysis section' is modular, and can be run independently. If the alignments of DNA to reference microbiome genomes is available, we could just run the community profiling
```
nohup bash wgs_smooth_woltka.sh -s franzosa2018 --run_woltka > profiling.log &
```

## Output

Below is a schematic of the folders produced after a full run of the software is completed. The software generates the directories and subdirectories to ensure the strucutre is preserved. Only folders relevant for each step of the analysis that was run are generated.

```
STUDY_FOLDER
	|
	|-- 00.rawdata
	|
	|-- 01.cleandata
	|	|
	|	|-- host
	|	|
	|	|-- non-host
	|	|
	|	|-- microbiome
	|
	|-- 02.annotations
	|	|
	|	|-- mapdir
	|	|
	|	|-- taxonomy
	|	|
	|	|-- functional
	|
	|-- 03.modules
	|
	|-- nohups
 ```

### Description of directories and sub-directories

* `STUDY_FOLDER` is determined by the argument `-s` if data is downloaded from ENA, or by the user, if working with their data.
* `00.rawdata` is where ENA-downloaded fastq files are stored.
* `01.cleandata` has the .log files produced by kneaddata.
*	`01.cleandata/host` fastq files with sequences identified as belonging to the host (therefore removed from next steps).
*       `01.cleandata/non-host` fastq files with sequences that couldn't be identified as belonging to the host (used as input to identify microbiome sequences).
*       `01.cleandata/microbiome` fastq files with sequences that are non-host and also aligned to any of the genomes included in the microbiome index. 
* `02.annotations`
*       `02.annotations/mapdir` has files generated by woltka used to annotate taxonomy and functions.
*       `02.annotations/taxonomy` has one table where the microbiome composition (rows) of each sample (column) is generated.
*       `02.annotations/functional` has two functional tables where KOs (rows) identified for each sample (column) are described. There are two as it has a stratified and unstratified proling.
* `03.modules` has four files per group of modules used. It calculates the stratified and unstratified presence of modules, and generates coverage and abundances of modules for each of those tables.
* `nohups` is where the files saving the progress of the script are stored.


## To do list

* (1) Add references and links to this readme.
* (2) Complete the documentation of sections with < > brackets.
* (3) Path to trimmomatic is hard coded. Make the software to look at path.
* (4) Path to sub scripts is hard coded. Think of best way to handle that. 
