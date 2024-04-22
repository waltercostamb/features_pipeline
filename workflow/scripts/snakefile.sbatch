#!/bin/bash
#SBATCH --job-name=smk_features
#SBATCH --output=smk_features_%j.out
#SBATCH --error=smk_features_%j.err
#SBATCH --cpus-per-task=60
#SBATCH --hint=nomultithread
#SBATCH --partition=standard
#SBATCH --mem=60G

#Load any necessary modules for snakemake 
module purge
source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v8.3.1

#Run Snakemake
snakemake --use-conda --conda-frontend conda --cores 3 --configfile config/config.json
conda deactivate
