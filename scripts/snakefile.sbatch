#!/bin/bash
#SBATCH --job-name=smk_features
#SBATCH --output=smk_features_%j.out
#SBATCH --error=smk_features_%j.err
#SBATCH --cpus-per-task=90
#SBATCH --partition=standard
#SBATCH --mem=90G

#Load any necessary modules for snakemake 
module purge
source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v8.3.1

#Run Snakemake
#Change path of Snakefile if necessary
snakemake --use-conda --cores 3 --configfile config/config.json --snakefile workflow/Snakefile
conda deactivate
