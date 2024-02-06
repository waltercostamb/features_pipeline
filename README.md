# Features pipeline

This is a snakemake pipeline to extract features from bacterial genomes. The final product will be delivered to Swapnil and available for use for the VEO/MGX groups.

<p align="center">
  <img src="./figures/features_pipeline.png" alt="Alt Text" width="450"/>
</p>

According to https://snakemake.readthedocs.io/en/latest/tutorial/tutorial.html#tutorial, "a Snakemake workflow scales without modification from single core workstations and multi-core servers to cluster or batch systems.". Our aim with this pipeline is for users of the VEO/MGX groups to be able to use the pipeline in draco using the power of the slurm cluster.  

# Usage

## Prepare your data

Before running the pipeline, you have to make sure everything is set in your folder.

- Make sure the directory which contains your bacterial genomes (or contigs) is named *genomes* (in lowercase, as the example of the GIT page https://github.com/waltercostamb/features_pipeline)
- Make sure the FASTA files have the extension *.fasta*
- To be sure that the output refers to the correct input file, name your files as follows: FILE\_ID.fasta

Example input:  

```
$ls genomes/
1266999.fasta  743966.fasta  GCA\_900660695.fasta
```

Example output of the kmer rule containing individual kmer profiles and a TSV file combining all files:

```
$ls output/kmer_files/ 
1266999_kmer9.txt  743966_kmer9.txt  GCA_900660695_kmer9.txt
$ls output/
kmer9_profiles.tsv
```

- Create file *files.txt* containing the IDs you want to run through the pipeline using the following command:

```
ls -lh genomes/ | sed 's/  */\t/g' | cut -f9 | sed 's/\.fasta//g' | grep -v '^$' > files.txt
```

## Run the pipeline

After preparing your data, to run this pipeline, you can either:  

- Submit an sbatch file to slurm, as if the Snakefile would be a usual script

```
sbatch snakefile.sbatch 
```

or:

- Allocate a node and run Snakemake directly in the command line, as below. Importantly, some of the software used within Snakefile do not run in the standard node. They require more memory. Therefore, use it in a gpu or fat node.

```
#Allocate a node: gpu or fat
salloc -p gpu --gres=gpu:1 
salloc -p fat -N 1

#Activate Snakemake
source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate snakemake_v7.24.0

#Run snakemake. Obs: make sure the feature you want is activated in the Snakfile
snakemake --use-conda --cores 1 --configfile config.json --snakefile /home/no58rok/features_pipeline/Snakefile
```

To make sure the desired feature is activated in the Snakefile: open Snakefile, uncomment the command line(s) referring to the desired feature, comment the other command lines.

# Example

As an example on how to run the pipeline, use the files given as input and the config.file. Run it in an allocated node or as an sbatch script.


# Available features  

To activate a feature, go to Snakefile and uncomment the line corresponding to the desired rule. Make sure that your genomes are in folder input and that the list of IDs is in file *genomes.txt*.

## kmers

kmers are sub-sequences of a genome. Kmers have length k, which can be defined by the user. The default is 9. If you want a different k, change it in file config.json. Kmers are calculated with Gerbil. An in-house script creates a table with kmers per file ID. Rule: kmers.

## Gene families

Genes are first predicted with CheckM (which uses prodigal internally) from the bacterial genomes. Afterwards, families are assigned with eggnog emapper. Finally, an in-house script creates a table with gene families per file ID: 1 symbols the presence of that family in the file ID, while 0 symbols absence.
Rules: genes_checkm and gene_families_emapper. 

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


