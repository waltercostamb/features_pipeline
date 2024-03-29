#Developer: Maria Beatriz Walter Costa, waltercostamb@gmail.com
#This pipeline extracts diverse features from bacterial genomes.

import argparse
import sys
import json

#Create argument parser
parser = argparse.ArgumentParser(description="Your script description")

#Add command-line arguments
parser.add_argument("--configfile", help="Path to the config file")
parser.add_argument("--snakefile", help="Path to the Snakefile")
parser.add_argument("--cores", type=int, help="Number of cores to use")
parser.add_argument("--use-conda", action="store_true", help="Use Conda")
parser.add_argument("--dag", action="store_true", help="Generate DAG")

#Parse the command-line arguments
args = parser.parse_args()

#Access the command line arguments
config_file_name = args.configfile
snakefile_path = args.snakefile
cores = args.cores
use_conda = args.use_conda
generate_dag = args.dag

#Add variables of general use
scripts				= "/home/no58rok/features_pipeline/scripts"

#print(type(config_file_name))
#<class 'str'>

#Read variables from the specified config file
with open(config_file_name, 'r') as config_file:
    config_data = json.load(config_file)

#print(type(config_file))
#<class '_io.TextIOWrapper'>

if generate_dag:  # Added block
    # Generate DAG
    #dag_command = f"snakemake --snakefile /home/no58rok/features_pipeline/Snakefile --dag | dot -Tpng > dag.png"
    dag_command = f"snakemake --snakefile /home/no58rok/features_pipeline/Snakefile --dag"
    subprocess.run(dag_command, shell=True)

#Store variables from the loaded JSON data (config file)
genomes 			= config_data["genomes"]
output_features			= config_data["output_folder"]
K 				= int(config_data["K"])
threads_gerbil 			= int(config_data["threads_gerbil"])
threads_checkm 			= int(config_data["threads_checkm"])
threads_emapper 		= int(config_data["threads_emapper"])
emapper_seed_ortholog_evalue 	= int(config_data["emapper_seed_ortholog_evalue"])
emapper_block_size 		= int(config_data["emapper_block_size"])

#Read the list of genome files
genomeID_lst = []
fh_in = open(genomes, 'r')
for line in fh_in:
    line = line.rstrip()
    genomeID_lst.append(line)



#Thi is the default target rule. 
#You should only add the final target (file/directory) per feature, otherwise it gives errors, due
# to the order of execution from snakemake
#For instance, to obtain gene-family_profiles.csv, Snakefile needs to run: 1) genes_checkm -> 2) gene_families_emapper -> 3) gene_families_table. So, do not add the "intermediate" outputs of 1 or 2, but rather only the output of 3.
rule all:
	input: 
		#kmers_gerbil
		#expand("{output_features}/kmer_files/{id}_kmer{K}.txt", id=genomeID_lst, K=K, output_features=output_features),
		#kmers_table
		expand("{output_features}/kmer{K}_profiles.tsv", output_features=output_features, K=K),
		#genes_checkm_lineage
		#expand("{output_features}/bins/{id}/genes.faa", id=genomeID_lst, output_features=output_features)
		#genes_checkm_lineage_yaml
		#expand("{output_features}/bins/{id}/genes.gff", id=genomeID_lst, output_features=output_features)
		#genes_checkm_qa
		expand("{output_features}/bins/{id}/{id}-qa.txt", id=genomeID_lst, output_features=output_features),
		#gene_families_emapper
		#expand("{output_features}/proteins_emapper/{id}", id=genomeID_lst, output_features=output_features)
		#gene_families_table
		expand("{output_features}/gene-family_profiles.csv", output_features=output_features),
		#isoelectric_point
		#expand("{output_features}/isoelectric_point_files/{id}-iso_point.csv", id=genomeID_lst, output_features=output_features)
		#isoelectric_point_table
		expand("{output_features}/iso-points_profiles_known_orthologs.csv", output_features=output_features)

#Rule to generate k-mer counts using Gerbil
rule kmers_gerbil:
	input:
		genome="genomes/{id}.fasta"
	output:
		kmers="{output_features}/kmer_files/{id}_kmer{K}.txt"
	params:
		k=K,
		t=threads_gerbil
	shell:
		r"""
		#Create output folder if it has not been done before
		if [ ! -d {output_features} ]; then 
			mkdir {output_features}
		fi
		
		#Create output folder of Gerbil's output files
		if [ ! -d {output_features}/kmer_files ]; then 
           		mkdir {output_features}/kmer_files
		fi

		#Run Gerbil
	        /home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -t {params.t} -k {params.k} -l 1 -o fasta {input.genome} {wildcards.id} {output.kmers}
        	"""

#Rule to generate a table from the k-mer counts
rule kmers_table:
	input:
		kmers=expand("{output_features}/kmer_files/{id}_kmer{K}.txt", id=genomeID_lst, output_features=output_features, K=K)
	output:
		"{output_features}/kmer{K}_profiles.tsv"
	params:
		k=K
	shell:
		r"""
		#Create list of files
      	  	ls -lh {output_features}/kmer_files/*kmer{params.k}.txt | sed 's/  */\t/g' | cut -f9 | sed 's/{output_features}\/kmer_files\///g' | sed 's/_kmer{params.k}.txt//g' > list_kmer{params.k}_files.txt
		
		#Create tmp folder
		if [ ! -d tmp ]; then 
           		mkdir tmp
		fi

		#Run scripts to convert Gerbil output formats
		python3 {scripts}/d_make_kmer_table.py list_kmer{params.k}_files.txt tmp {params.k} {output_features}
		python3 {scripts}/d_append_agg_kmer_tables.py list_kmer{params.k}_files.txt {output_features}/kmer_files

		mv {output_features}/kmer_files/kmer{params.k}_profiles.tsv {output_features}/.
		rm -r tmp/
		rm list_kmer{params.k}_files.txt
        	"""

#Rule to run checkm lineage_wf using shell
rule genes_checkm_lineage:
	input:
		genome_folder=expand("genomes"),
		genomes=expand("genomes/{id}.fasta",id=genomeID_lst)
	output:
		checkm=expand("{output_features}/bins/{id}/genes.faa", id=genomeID_lst, output_features=output_features)
	params:
		t=threads_checkm
##	conda:
##		checkm_smk.yml
	shell:
		r"""
		bash -c '
		#Create output folder if it has not been done before
		if [ ! -d {output_features} ]; then 
			mkdir {output_features}
		fi

            	. $HOME/.bashrc # if not loaded automatically
		conda init bash

		#Activate conda environment
		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
            	conda activate checkm_v1.2.2

                #Run checkm lineage only once
                checkm lineage_wf -t {params.t} -x fasta {input.genome_folder} {output_features}
                #Substitute checkm run for a simple copying of backup files (for debug purposes)
                #cp -r checkm_output/bins {output_features}/.
                #cp -r checkm_output/lineage.ms {output_features}/.
		'
		"""

#Rule to run checkm lineage_wf using a YAML file instead of the shell
rule genes_checkm_lineage_yaml:
	input:
		genome_folder=expand("genomes"),
		genomes=expand("genomes/{id}.fasta",id=genomeID_lst)
	output:
		checkm=expand("{output_features}/bins/{id}/genes.gff", id=genomeID_lst, output_features=output_features)
	params:
		t=threads_checkm
	conda:
		"checkm_smk.yml"
	shell:
		"""
		#Create output folder if it has not been done before
		if [ ! -d {output_features} ]; then 
			mkdir {output_features}
		fi

                #Run checkm lineage_wf
                checkm lineage_wf -t {params.t} -x fasta {input.genome_folder} {output_features}
		"""

#Rule to run checkm_qa 
rule checkm_qa:
	input:
		checkm="{output_features}/bins/{id}/genes.faa"
	output:
		checkm_qa="{output_features}/bins/{id}/{id}-qa.txt"
	params:
		t=threads_checkm
	shell:
		r"""
		bash -c '
            	. $HOME/.bashrc 
		conda init bash

		#Activate conda environment
		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
            	conda activate checkm_v1.2.2

                #Run checkm qa for every ID
                checkm qa -o 2 -f {output.checkm_qa} {output_features}/lineage.ms {output_features}
		'
		"""

rule gene_families_emapper:
	input:
		checkm="{output_features}/bins/{id}/genes.faa"
	output:
		emapper=directory("{output_features}/proteins_emapper/{id}")
	params:
		t=threads_emapper,
		e=emapper_seed_ortholog_evalue,
		b=emapper_block_size
#	conda:
#		"checkm_v1.2.2.yaml"
#		"checkm_v1.2.2"
	shell:
		r"""
                bash -c '
                . $HOME/.bashrc 
                conda init bash
                source /home/xa73pav/tools/anaconda3/etc/profile.d/conda.sh
                conda activate eggnog-mapper_v2.1.11

		if [ ! -d "{output_features}/proteins_emapper" ]; then 
			mkdir "{output_features}/proteins_emapper"
		fi
		
		if [ ! -d "{output_features}/proteins_emapper/{wildcards.id}" ]; then 
			mkdir "{output_features}/proteins_emapper/{wildcards.id}"
		fi

		#Substitute emapper run for a backup files copy (for debugging)
	        #cp -r backup_proteins_emapper/{wildcards.id} {output_features}/proteins_emapper/.
                emapper.py --cpu {params.t} --data_dir /work/groups/VEO/databases/emapper/v20230620 -o {wildcards.id} --output_dir {output.emapper} -m diamond -i {input.checkm} --seed_ortholog_evalue {params.e} --go_evidence non-electronic --tax_scope auto --target_orthologs all --block_size {params.b}
                '
                """	

rule gene_families_table:
	input:
		emapper=expand("{output_features}/proteins_emapper/{id}", id=genomeID_lst, output_features=output_features)
	output:
		gene_profiles="{output_features}/gene-family_profiles.csv"
#       conda:
#               "checkm_v1.2.2.yaml"
#               "checkm_v1.2.2"
	shell:
		r"""
		bash -c '
                . $HOME/.bashrc
                conda init bash
                source /home/xa73pav/tools/anaconda3/etc/profile.d/conda.sh
                # Activate the python3 environment
                conda activate /home/no58rok/tools/miniconda3/envs/bacterial_phenotypes
                
                #Run script to make a table out of the emapper output from rule gene_families_emapper
                python3 {scripts}/genes_table.py files.txt {output_features}/proteins_emapper/ {output_features}/
                '
                """

rule isoelectric_point:
	input:
		checkm="{output_features}/bins/{id}/genes.faa"
	output:
		isoelectric_point="{output_features}/isoelectric_point_files/{id}-iso_point.csv"
	shell:
		r"""
		bash -c '
            	. $HOME/.bashrc 
		conda init bash
	        # Activate the python3 environment
                conda activate /home/no58rok/tools/miniconda3/envs/bacterial_phenotypes
		
		#Create output folder
		if [ ! -d {output_features}/isoelectric_point_files ]; then 
           		mkdir {output_features}/isoelectric_point_files
		fi

		#Create output folder
		if [ ! -d tmp_{wildcards.id} ]; then 
           		mkdir tmp_{wildcards.id}
		fi

		#Split genes.faa
		bash {scripts}/split_protein_file.sh {output_features}/bins/{wildcards.id}/genes.faa tmp_{wildcards.id}

		#Enter in folder to avoid producing many tmp files in main folder
		counter=1

		(cd tmp_{wildcards.id}
		#Loop for each split file to calculate isoelectric point
		for file in ./*faa; do
			python3 {scripts}/emboss_pepstats.py --email jena@email.de --sequence "$file" --quiet --outfile {wildcards.id}-"$counter"
			((counter++))
		done
		cd ..
		)

		#Cat all outputs into one file
		cat tmp_{wildcards.id}/{wildcards.id}*.out.txt > {output_features}/isoelectric_point_files/{wildcards.id}-emboss.out

		#Extract protein names and isoelectric points and save into output file 
		python3 {scripts}/extract_isoeletric-point.py {output_features}/isoelectric_point_files/{wildcards.id}-emboss.out > {output_features}/isoelectric_point_files/{wildcards.id}-iso_point.csv

		#Remove unnecessary output from emboss
		rm -r tmp_{wildcards.id} 
		'
		"""

rule isoelectric_point_table:
	input:
		isoelectric_point=expand("{output_features}/isoelectric_point_files/{id}-iso_point.csv", id=genomeID_lst, output_features=output_features),
		emapper=expand("{output_features}/proteins_emapper/{id}", id=genomeID_lst, output_features=output_features)
	output:
		iso_profiles="{output_features}/iso-points_profiles_known_orthologs.csv"
	shell:
		r"""
		bash -c '
                . $HOME/.bashrc
                conda init bash
                source /home/xa73pav/tools/anaconda3/etc/profile.d/conda.sh
                # Activate the python3 environment
                conda activate /home/no58rok/tools/miniconda3/envs/bacterial_phenotypes
                
                #Run script to make a table out of the EMBOSS stats output from rule isoelectric_point
                python3 {scripts}/iso-point_table.py {genomes} {output_features}/proteins_emapper/ {output_features}/ {output_features}/isoelectric_point_files/
                '
                """


#rule pfam:
#	input:
#		checkm="output/bins/{id}/genes.faa"
#	output:
#		?
#	shell:
#		r"""
#		#Create output folder if it has not been done before
#		if [ ! -d output_features ]; then 
#			mkdir output_features
#		fi
#		#Run HMMER
#		/home/groups/VEO/tools/hmmer/v3.3.1/bin/hmmsearch input.checkm DB_PATH	
#		"""

#rule dram:


