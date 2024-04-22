# Snakemake workflow: Features Pipeline

A Snakemake workflow for extracting features from bacterial genomes, such as kmers and gene families. In this tutorial, you will learn how to use the pipeline with the example input provided in folder ```genomes```. After learning, you can use it with your own data. 

<p align="center">
  <img src="./figures/features_pipeline.png" alt="Alt Text" width="550"/>
</p>

Within the pipeline the following software are used:

- Jellyfish: https://github.com/gmarcais/Jellyfish
- CheckM: https://github.com/Ecogenomics/CheckM
- EMBOSS pepstats: https://www.ebi.ac.uk/jdispatcher/docs/
- EggNOG emapper: https://github.com/eggnogdb/eggnog-mapper

# Installation

## Cloning the repository

The first step to use the pipeline is to clone the GIT repository:

```
#Clone using https
git clone https://github.com/waltercostamb/features_pipeline.git
```

You could clone the repository using something else from https. To know what is the best option for you, consult your admin.

## Downloading databases

If you are using this pipeline in the draco high-performance cluster and are part of the VEO group, skip this section.  

After cloning the repository, you need to download the database required by EggNOG emapper:

- Install EggNOG emapper: https://github.com/eggnogdb/eggnog-mapper/wiki/eggNOG-mapper-v2.1.5-to-v2.1.12#installation
- Download the database with ```download_eggnog_data.py``` following: https://github.com/eggnogdb/eggnog-mapper/wiki/eggNOG-mapper-v2.1.5-to-v2.1.12#setup This should download a DB of ~50 GB
- Change file ```config/config.json``` to update parameter "emapper_db_dir". This parameter contains the path to the eggnog database. The default is ```/work/groups/VEO/databases/emapper/v20230620```

# Usage

After cloning the repository, do the following steps:

- Create ```config/files.txt``` with the list of the input files provided in the repository with the command line below:

```
ls -lh genomes/ | sed 's/  */\t/g' | cut -f9 | sed 's/\.fasta//g' | grep -v '^$' > config/files.txt
```

To use the pipeline with the example files, you can submit a job to the slurm queue with ```workflow/scripts/snakemake.sbatch```: 

```
sbatch workflow/scripts/snakefile.sbatch
```

If you use the default configurations (parallelization of 3, 30 cores and 30 GB per file), the pipeline should take 26 minutes to run.   

If you are not using the draco cluster, you should adapt ```workflow/scripts/snakemake.sbatch``` to your cluster. Most importantly, change the conda activation command lines. For installation of snakemake, consult: https://snakemake.readthedocs.io/en/stable/getting_started/installation.html.

## Expected output

The example input you just submitted to the queue contains the three following genomes:

```
$ls genomes/
1266999.fasta  743966.fasta  GCA_900660695.fasta
```

If you run the example input, you will obtain their kmer profiles, gene families, checkm qa reports and isoelectric points of proteins. The output of the kmer rule follows:

```
#Individual kmer profiles
$ls output/kmer_files/ 
1266999_kmer9.txt  743966_kmer9.txt  GCA_900660695_kmer9.txt
#TSV file combining all profiles
$ls output/
kmer9_profiles.tsv
```

## Use the pipeline with your data

To use the pipeline with your own data:

- Make sure the directory which contains your bacterial genomes (or contigs) is named ```genomes``` (in lowercase)
- Make sure the FASTA files have the extension ```.fasta```
  - the pipeline assumes your files are named in the following way: ```FILE\_ID.fasta```
- Create ```config/files.txt``` containing the FILE\_IDs you want to run through the pipeline:

```
ls -lh genomes/ | sed 's/  */\t/g' | cut -f9 | sed 's/\.fasta//g' | grep -v '^$' > config/files.txt
```

- Adapt (if needed) the config and/or sbatch files:

```
#Adapt files if needed
vim config/config.json
vim workflow/scripts/snakefile.sbatch
```

## Config.json

UNDER CONSTRUCTION.

## snakefile.sbatch

File ```workflow/scripts/snakefile.sbatch``` contains information for your cluster, such as required memory and threads. For just a few files, this is not a big concern. However, for a larger amount of files, you should make sure to allocate enough memory and threads. For calculation of requirements, check the "Performance" section below.

## Choosing specific rules

The default mode of Snakefile is to run all rules. If you want to run one or only a few specific rules, change the commented lines in `rule all` of the Snakefile.

# Performance

Below follows the time and memory performance of the pipeline for 3 different input sizes. For these calculations, we used 1 core and default parameters of ```config/config.json```. Note that "emapper_block_size" is already set to a higher value of 10.0 in ```config/config.json```. The default value of EggNOG emapper's "emapper_block_size" is actually 2.0. Increasing this value to 10.0 increases memory consumption, but reduces run time.  

Time performance            |  Memory performance
:-------------------------:|:-------------------------:
![](./figures/performance_plot1_features_pipeline.png)  |  ![](./figures/performance_plot2_features_pipeline.png)

*CheckM lineage_wf* is required for the following rules: *isoelectric_point*, *genes_checkm_lineage* and *checkM_qa*. It is the most memory demanding process, causing the memory requirements to be the same for these three rules.  

Aditionally, the run time to calculate the isoelectric points (IP) per file is ~2min 10sec. This was calculated as the average run time of 500 files. In addition to calculating the IPs, the rule *isoelectric_point* also requires *CheckM lineage_wf*.  

The run time to calculate qa reports with *CheckM qa* is ~6min 7sec. This was calculated as the average run time of 160 files. Similarly as for rule *isoelectric_point*, the rule *checkM_qa* also requires *CheckM lineage_wf*.  

The run time to calculate EggNOG emapper reports is ~12min. This was calculated as the average run time of 250 files. The rule *genes_checkm_lineage* also requires *CheckM lineage_wf*. Below follows an example of how this information can be used to calculate run time and required memory to parallelize the *gene_families_emapper* rule.

# Parallelization

Use the following formula to calculate threads and memory requirements.

- Run time of 1 file = 12 min, given 40 threads and 30 GB memory

Parallelizing the pipeline for 6 files, yields:

- Run time of 6 files = 12 min, given 6 x 40 threads and 6 x 30 GB memory 

The default parallelization of the pipeline is 3. If you want to change that, modify file ```workflow/scripts/snakefile.sbatch```. For 6 files, you can change the default to: 

```
#!/bin/bash
#SBATCH --job-name=smk_features
#SBATCH --output=smk_features_%j.out
#SBATCH --error=smk_features_%j.err
#SBATCH --cpus-per-task=240
#SBATCH --partition=standard
#SBATCH --mem=180G

module purge
source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v8.3.1

snakemake --use-conda --conda-frontend conda --cores 6 --configfile config/config.json
conda deactivate
```

If you are not using the draco cluster, adapt file ```workflow/scripts/snakefile.sbatch``` to your needs.

# Available features

A directed acyclic graph (DAG) is shown for each feature. It describes the pipeline's hierarchy of rules. Below you see a simplified DAG with all implemented rules for one input genome.

<p align="center">
  <img src="./figures/DAG_features_pipeline.png" alt="Alt Text" width="550"/>
</p>

## kmers

kmers are sub-sequences of a genome. Kmers have length k, which can be defined by the user. The default is 9. If you want a different k, change it in file config.json. Kmers are calculated with Gerbil. An in-house script creates a table with kmers per file ID. Rule: kmers.

<p align="center">
  <img src="./figures/dag_kmers.png" alt="Alt Text" width="350"/>
</p>

## Gene families

Genes are first predicted with CheckM (which uses prodigal internally) from the bacterial genomes. Afterwards, families are assigned with eggnog emapper. Finally, an in-house script creates a table with gene families per file ID: 1 symbols the presence of that family in the file ID, while 0 symbols absence.
Rules: genes_checkm and gene_families_emapper. 


<p align="center">
  <img src="./figures/dag_gene_families.png" alt="Alt Text" width="700"/>
</p>

## GC content

Is calculated by CheckM. 
Rule: genes_checkm. 

## Genome size (nt)

Is calculated by CheckM. 
Rule: genes_checkm. 

## Genome completeness

Is calculated by CheckM. 
Rule: genes_checkm. 

## Isoelectric points of proteins 

Proteins are annotated by checkM (using prodigal internally). Isoelectric point of proteins is calculated by EMBOSS pepstats. Lastaly, the output of pepstats is formated by an in-house script.
Rules: genes_checkm and isoelectric_point.


