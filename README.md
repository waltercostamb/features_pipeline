# Features pipeline

This pipeline extracts features from bacterial genomes.  

<p align="center">
  <img src="./figures/features_pipeline.png" alt="Alt Text" width="450"/>
</p>

Example input:  

```
$ls genomes/
1266999.fasta  743966.fasta  GCA_900660695.fasta
```

Example output of the kmer rule:

```
#Individual kmer profiles
$ls output/kmer_files/ 
1266999_kmer9.txt  743966_kmer9.txt  GCA_900660695_kmer9.txt
#TSV file combining all profiles
$ls output/
kmer9_profiles.tsv
```

# Usage 

To learn how to use the pipeline, run it for the example genomes provided in the repository. 
First, copy the folder *genomes* to the path you wish to run the pipeline along with the config and sbatch files:

```
cd PATH
cp -r /home/no58rok/features_pipeline/genomes .
cp /home/no58rok/features_pipeline/config.json .
cp /home/no58rok/features_pipeline/snakefile.sbatch .
```

## Prepare your data

- Make sure the directory which contains your bacterial genomes (or contigs) is named *genomes* (in lowercase)
- Make sure the FASTA files have the extension *.fasta*
  - the pipeline assumes your files are named in the following way: FILE\_ID.fasta
- Create *files.txt* containing the FILE\_IDs you want to run through the pipeline:

```
ls -lh genomes/ | sed 's/  */\t/g' | cut -f9 | sed 's/\.fasta//g' | grep -v '^$' > files.txt
```

- Adapt the config file or the snakefile if needed

## Run the pipeline

- Submit an sbatch file to slurm, as if the Snakefile would be a usual script:

```
sbatch snakefile.sbatch 
```

or:

- Allocate a node
- run Snakemake directly in the command line, as below

Importantly, some of the required software do not run in the standard node, since they require more memory. Use gpu or fat.

```
#Allocate a node
salloc -p gpu --gres=gpu:1 
salloc -p fat -N 1

#Activate Snakemake
source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate snakemake_v7.24.0

#Run snakemake
snakemake --use-conda --cores 1 --configfile config.json --snakefile /home/no58rok/features_pipeline/Snakefile
```
## Run specific rules

The default mode of Snakefile is to run all rules. If you want to run a specific rule, open Snakefile, uncomment the command line(s) referring to the desired feature(s) and comment the other lines.

# Available features

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


