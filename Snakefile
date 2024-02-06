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



#This rule is the default target rule. 
#You should only add the final target file/directory per feature, otherwise it gives errors, since
# there is an order of execution
#For instance, to obtain gene-family_profiles.csv, Snakefile needs to run: 1) genes_checkm -> 2) gene_families_emapper -> 3) gene_families_table. So, do not add the "intermediate" outputs of 1 or 2, but rather only the output of 3.
rule all:
	input: 
		#kmers
		expand("{output_features}/kmer_files/{id}_kmer{K}.txt", id=genomeID_lst, K=K, output_features=output_features),
		#genes_checkm
		#expand("{output_features}/bins", output_features=output_features),
		#gene_families_emapper
		#expand("{output_features}/proteins_emapper", output_features=output_features)
		#gene_families_table
		expand("{output_features}/gene-family_profiles.csv", output_features=output_features),
		#isoelectric_point
		expand("{output_features}/isoelectric_point_files", id=genomeID_lst, output_features=output_features)

#Rule to generate k-mer counts using Gerbil and formatting the output
rule kmers:
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

		#Gerbil
	        /home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -t {params.t} -k {params.k} -l 1 -o fasta {input.genome} temp {output.kmers}

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

#Rule to run checkm 
rule genes_checkm:
	input:
		genomes="genomes"
	output:
		checkm=directory("{output_features}/bins")
		#DO NOT use line below, otherwise checkm runs several times
		#checkm="{output_features}/bins/{id}/genes.faa"
	params:
		t=threads_checkm
##	conda:
##		"checkm_v1.2.2.yaml"
##		"checkm_v1.2.2"
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
                checkm lineage_wf -t {params.t} -x fasta {input.genomes} {output_features}
                #Substitute checkm run for a simple copying of backup files (for debug purposes)
                #cp -r checkm_output/bins {output_features}/.
                #cp -r checkm_output/lineage.ms {output_features}/.

                #Run checkm qa for every ID
                while IFS= read -r line; do
                        checkm qa -o 2 -f {output_features}/bins/$line/$line-qa.txt {output_features}/lineage.ms {output_features}
                done < files.txt
		'
		"""

rule gene_families_emapper:
	input:
		checkm="{output_features}/bins"
	output:
		emapper=directory("{output_features}/proteins_emapper")
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

		if [ ! -d "{output_features}/protein_emapper" ]; then 
			mkdir "{output_features}/proteins_emapper"
		fi
		if [ ! -d "{output.emapper}" ]; then 
			mkdir "{output.emapper}"
		fi

                #Run eggnog emapper
                while IFS= read -r line; do
                	#Substitute emapper run for a backup files copy (for debugging)
	                #cp -r backup_proteins_emapper/$line {output_features}/proteins_emapper/.
                	emapper.py --cpu {params.t} --data_dir /work/groups/VEO/databases/emapper/v20230620 -o $line --output_dir {output.emapper} -m diamond -i {output_features}/bins/$line/genes.faa --seed_ortholog_evalue {params.e} --go_evidence non-electronic --tax_scope auto --target_orthologs all --block_size {params.b}
                done < files.txt
                '
                """	



rule gene_families_table:
        input:
                emapper="{output_features}/proteins_emapper"
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
		checkm="{output_features}/bins"
	output:
		isoelectric_point=directory("{output_features}/isoelectric_point_files")
	shell:
		r"""
		bash -c '
		#Create output folder if it has not been done before
		if [ ! -d {output_features} ]; then 
			mkdir {output_features}
		fi

            	. $HOME/.bashrc 
		conda init bash
	        # Activate the python3 environment
		conda activate bacterial_phenotypes
		
		#Create output folder
		if [ ! -d {output_features}/isoelectric_point_files ]; then 
           		mkdir {output_features}/isoelectric_point_files
		fi

                while IFS= read -r line; do
			#Create tmp folder
        		mkdir "tmp_$line"

			#Split genes.faa
			bash {scripts}/split_protein_file.sh {input.checkm}/$line/genes.faa "tmp_$line"

			#Enter in folder to avoid producing many tmp files in main folder
			counter=1

			(cd "tmp_$line"
			#Loop for each split file to calculate isoelectric point
			for file in ./*faa; do
				python3 {scripts}/emboss_pepstats.py --email jena@email.de --sequence "$file" --quiet
				mv emboss*.out.txt "emboss$counter.out"
				((counter++))
			done
			cd ..
			)

			#Remove unnecessary output from emboss
			rm tmp_$line/emboss*.sequence.txt
			rm tmp_$line/emboss*.submission.params

			#Cat all outputs into one file
			cat tmp_$line/emboss*.out > tmp_$line/tmp_emboss_all.out

			#Extract protein names and isoelectric points and save into output file 
			python3 {scripts}/extract_isoeletric-point.py tmp_$line/tmp_emboss_all.out > {output.isoelectric_point}/$line-iso_point.csv
			rm -r tmp_$line 
                done < files.txt
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


