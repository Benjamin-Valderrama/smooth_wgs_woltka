## Smooth analysis

Here I share scripts I made for the analysis of microbiome data. The scripts allows the user to perform the following tasks: 
* (1) Data adquisition : fastq-dl is used to download fastq files from ENA
* (2) Data quality control and host decontamination : kneaddata is used
* (3) Alignment of microbiome DNA to reference db : bowtie2 is used to generate the sequences alignment. Woltka's default db is used as a reference.
* (4) Community profiling : Woltka is used to generate the taxonomic and functional profile of the microbiome.
* (5) Pathways annotation : Omixer is used to generate annotation of GBMs, pathways involved in the synthesis and degradation of neuroactive compounds.

## Requirements

The scipts assume micromamba is used to manage different software and the following environments are available to the user:

* (1) fastq-dl
* (2) kneaddata
* (3) woltka

The environments can be created from the files provided in the `envs` folder as follows:
```CODE```

## Usage

We look at the help message of the software
```HELP MESSAGE```

We could run the analysis of the following microbiome dataset
```CODE```

If we already have fastq files, we could run the analysis from an existing directory
```CODE```

Each step described in the 'Smooth analysis section' is modular, and can be run independently. If the alignments of DNA to reference microbiome genomes is available, we could just run the community profiling
```CODE```

## Output

Below is a schematic of the folder produced after a full run of the software is completed. The software generates the directories and subdirectories to ensure the strucutre is preserved. Only folders relevant for each step of the analysis that was run are generated.

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
	|	|
	|	|-- KNEADDATA LOG FILES
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
 ```

### Description of directories and sub-directories

## To do list

(1) Add references and links to this readme.
(2) Complete the documentation of sections with < > brackets.
(3) Path to trimmomatic is hard coded. Make the software to look at path.
(4) Path to sub scripts is hard coded. Think of best way to handle that. 
