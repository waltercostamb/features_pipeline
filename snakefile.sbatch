#!/bin/bash
#SBATCH --job-name=smk
#SBATCH --output=smk_%j.out
#SBATCH --error=smk_%j.err
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=3
#SBATCH --partition=standard
#SBATCH --mem=200G

#Load any necessary modules for snakemake 
#Change commands below if necessary
module purge
source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate snakemake_v7.24.0

#Run Snakemake
#Change path of Snakefile if necessary
snakemake --use-conda --cores 3 --configfile config.json --snakefile /home/no58rok/features_pipeline/Snakefile
conda deactivate
