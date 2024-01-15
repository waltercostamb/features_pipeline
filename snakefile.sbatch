#!/bin/bash
#SBATCH --job-name=smk_emapper
#SBATCH --output=smk_emapper_%j.out
#SBATCH --error=smk_emapper_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --partition=gpu
#SBATCH --mem=240G

# Load any necessary modules if needed
module purge

source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v7.24.0

# Run Snakemake
snakemake --use-conda --cores 1
conda deactivate
