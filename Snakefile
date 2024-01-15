#Developer: Maria Beatriz Walter Costa, waltercostamb@gmail.com
#This pipeline extracts diverse features from bacterial genomes.

import json

#Read variables from config.json file
with open('config.json', 'r') as config_file:
    config_data = json.load(config_file)

#Store variables from the loaded JSON data
genomes = config_data["genomes"]
K = int(config_data["K"])
threads_gerbil = int(config_data["threads_gerbil"])
threads_checkm = int(config_data["threads_checkm"])
threads_emapper = int(config_data["threads_emapper"])
emapper_seed_ortholog_evalue = int(config_data["emapper_seed_ortholog_evalue"])
emapper_block_size = int(config_data["emapper_block_size"])

#Read the list of genome files
genomeID_lst = []
fh_in = open(genomes, 'r')
for line in fh_in:
    line = line.rstrip()
    genomeID_lst.append(line)

#This rule is the default target rule. If you call snakemake with the command 
#below, it will produce the files specified in it
#snakemake --use-conda --cores 1
rule all:
	input: 
		#kmers
		expand("output/kmer_files/{id}_kmer{K}.txt", id=genomeID_lst, K=K),
		#genes_checkm
		expand("output/bins/{id}/genes.faa", id=genomeID_lst),
		#gene_families_emapper
		expand("output/proteins_emapper/{id}", id=genomeID_lst),
		#isoelectric point
		expand("output/isoelectric_point_files/{id}_iso-point.csv", id=genomeID_lst)


#Rule to generate k-mer counts using Gerbil and formatting the output
rule kmers:
	input:
		genome="input/{id}.fasta"
	output:
		kmers="output/kmer_files/{id}_kmer{K}.txt"
	params:
		k=K,
		t=threads_gerbil
	shell:
		r"""
		#Create output folder of Gerbil's output files
		if [ ! -d output/kmer_files ]; then 
           		mkdir output/kmer_files
		fi

		#Gerbil
	        /home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -t {params.t} -k {params.k} -l 1 -o fasta {input.genome} temp {output.kmers}

		#Create list of files
      	  	ls -lh output/kmer_files/*kmer{params.k}.txt | sed 's/  */\t/g' | cut -f9 | sed 's/output\/kmer_files\///g' | sed 's/_kmer{params.k}.txt//g' > list_kmer{params.k}_files.txt
		
		#Create tmp folder
		if [ ! -d tmp ]; then 
           		mkdir tmp
		fi

		#Run scripts to convert Gerbil output formats
		python3 scripts/d_make_kmer_table.py list_kmer{params.k}_files.txt tmp
		python3 scripts/d_append_agg_kmer_tables.py list_kmer{params.k}_files.txt output/kmer_files

		mv output/kmer_files/kmer{params.k}_profiles.tsv output/.
		rm -r tmp/
		rm list_kmer{params.k}_files.txt
        	"""

#Output of checkm DIRECTORY/bins/CAADIS000000000/genes.faa
#WARNING: do not change t to more than 20 (see wiki)
#To run this rule for one file: snakemake --use-conda --conda-frontend conda --cores 1 output/bins/1266999/genes.faa
#Rule to annotate genes (runs checkM lineage_wf and checkm qa)
rule genes_checkm:
	input:
		genomes="input"
	output:
		checkm="output/bins/{id}/genes.faa", 
		lineage=directory("output/bins/{id}"),
		qa="output/bins/{id}/{id}_qa.txt"
	params:
		t=threads_checkm
##	conda:
##		"checkm_v1.2.2.yaml"
##		"checkm_v1.2.2"
	shell:
		r"""
		bash -c '
            	. $HOME/.bashrc # if not loaded automatically
		conda init bash

		#Activate conda environment
		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
            	conda activate checkm_v1.2.2

#		CheckM takes a list of Fasta files from the input folder ({input.genomes})
		checkm lineage_wf -t {params.t} -x fasta {input.genomes} output
		checkm qa -o 2 -f {output.qa} output/lineage.ms output
		'
		"""
	
rule gene_families_emapper:
	input:
		checkm="output/bins/{id}/genes.faa"
	output:
		emapper=directory("output/proteins_emapper/{id}")
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

		mkdir output/proteins_emapper/{wildcards.id}
	
		#Run eggnog emapper
		emapper.py --cpu {params.t} --data_dir /work/groups/VEO/databases/emapper/v20230620 -o {wildcards.id} --output_dir {output.emapper} -m diamond -i {input.checkm} --seed_ortholog_evalue {params.e} --go_evidence non-electronic --tax_scope auto --target_orthologs all --block_size {params.b}

		#Line below is an alternative to emapper for debugging purposes
#		cp -r proteins_emapper_backup/{wildcards.id} output/proteins_emapper/.

		#Deactivate emapper conda and activate python3
		conda deactivate
	        # Activate the python3 environment
		conda activate /home/no58rok/tools/miniconda3/envs/bacterial_phenotypes

		ls -lh output/proteins_emapper/*/*annotations > pre_file_list.txt
		sed "s/  */\t/g" pre_file_list.txt | cut -f 9 | sed "s/\//\t/g" | cut -f3 > file_list.txt

		#Run script to make a table out of the emapper output from rule gene_families_emapper
		python3 scripts/genes_table.py file_list.txt output/proteins_emapper/ output/
		rm pre_file_list.txt
		rm file_list.txt
		'
		"""

rule isoelectric_point:
	input:
		checkm="output/bins/{id}/genes.faa"
	output:
		isoelectric_point="output/isoelectric_point_files/{id}_iso-point.csv"
	shell:
		r"""
		bash -c '
            	. $HOME/.bashrc 
		conda init bash
	        # Activate the python3 environment
		conda activate bacterial_phenotypes

		#Split genes.faa
		bash scripts/split_protein_file.sh {input.checkm}
		#Enter in folder to avoid producing many itmp files in main folder
		cd split_protein_files_tmp

		counter=1

		#Loop for each split file to calculate isoelectric point
		for file in ./*faa; do
			python3 ../scripts/emboss_pepstats.py --email veo.lab@uni-jena.de --sequence "$file" --quiet
			mv emboss*.out.txt "emboss$counter.out"
			((counter++))
		done

		#Remove unnecessary output from emboss
		rm emboss*.sequence.txt
		rm emboss*.submission.params

		#Cat all outputs into one file
		cat emboss*.out > tmp_emboss_all.out
		#Return to main folder
		cd ../

		#Create output folder
		if [ ! -d output/isoelectric_point_files ]; then 
           		mkdir output/isoelectric_point_files
		fi

		#Extract protein names and isoelectric points and save into output file 
		python3 scripts/extract_isoeletric-point.py split_protein_files_tmp/tmp_emboss_all.out > {output.isoelectric_point}
		rm -r split_protein_files_tmp
		'
		"""

#rule pfam:
#	input:
#		checkm="output/bins/{id}/genes.faa"
#	output:
#		?
#	shell:
#		r"""
#		#Run HMMER
#		/home/groups/VEO/tools/hmmer/v3.3.1/bin/hmmsearch input.checkm DB_PATH	
#		"""

#rule dram:


