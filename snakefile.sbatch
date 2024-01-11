#!/bin/bash
#SBATCH --job-name=smk_emapper
#SBATCH --output=smk_emapper_%j.out
#SBATCH --error=smk_emapper_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --partition=fat
#SBATCH --mem=500G

# Load any necessary modules if needed
module purge

source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v7.24.0

# Run Snakemake with the desired target rule(s)
snakemake --use-conda --conda-frontend conda --cores 1 output/proteins_emapper/{1266999,743966,GCA_900660695}

conda deactivate
