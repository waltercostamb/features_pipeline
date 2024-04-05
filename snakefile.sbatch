#!/bin/bash
#SBATCH --job-name=smk
#SBATCH --output=smk_%j.out
#SBATCH --error=smk_%j.err
#SBATCH --cpus-per-task=120
#SBATCH --partition=standard
#SBATCH --mem=30G

#Load any necessary modules for snakemake 
module purge
source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v8.3.1

#Run Snakemake
#Change path of Snakefile if necessary
snakemake --use-conda --cores 3 --configfile config.json --snakefile Snakefile
conda deactivate
