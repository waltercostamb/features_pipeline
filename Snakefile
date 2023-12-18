#Developer: Maria Beatriz Walter Costa, waltercostamb@gmail.com
#This pipeline extracts diverse features from bacterial genomes.

# Define the input and output files
K = 9 # Define k length

#Rule to generate k-mer counts using Gerbil and formatting the output
rule kmers:
	input:
		genome="input/{sample}.fasta"
	output:
		kmers="output/{sample}_kmer{K}.txt"
	params:
		k=K,
	threads: 10
	shell:
		r"""
		#Gerbil
	        /home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -e 30GB -t 10 -k {params.k} -l 1 -o fasta {input.genome} temp {output.kmers}

		#Create list of files
        	if [ -f list_kmer{params.k}_files.txt ]; then
           		rm list_kmer{params.k}_files.txt
      	  	fi
	
      	  	ls -lh output/*kmer{params.k}.txt | sed 's/  */\t/g' | cut -f9 | sed 's/output\///g' | sed 's/_kmer{params.k}.txt//g' > list_kmer{params.k}_files.txt
		
		#Create tmp folder
		if [ ! -d tmp ]; then 
           		mkdir tmp
		fi

		#Run scripts to convert Gerbil output formats
		python3 scripts/d_make_kmer_table.py list_kmer{params.k}_files.txt tmp
		python3 scripts/d_append_agg_kmer_tables.py list_kmer{params.k}_files.txt output

#TODO: remove intermediary files
#		rm output/*_kmer{params.k}.txt
#		rm -r tmp/
        	"""

#source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate checkm_v1.2.2 
#Output of checkm DIRECTORY/bins/CAADIS000000000/genes.faa
#source /home/xa73pav/tools/anaconda3/etc/profile.d/conda.sh && conda activate eggnog-mapper_v2.1.11
#Rule to annotate genes and assign orthologies
rule gene_families:
	input:
		genome="input"
	output:
		checkm="output/bins/{sample}/genes.faa", 
		lineage="output/bins/{sample}"
#	conda:
#		"checkm_v1.2.2.yaml"
#		"checkm_v1.2.2"
	shell:
		r"""
		bash -c '
            	. $HOME/.bashrc # if not loaded automatically
		conda init bash
		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh 
            	conda activate checkm_v1.2.2
#        	if [ -f {output.checkm} ]; then
		checkm lineage_wf -t 40 -x fasta {input.genome} output
#		fi
		checkm qa -o 2 -f {output.lineage}/*_qa.txt {output.lineage}/lineage.ms {output.lineage}
            	conda deactivate'

		#conda activate eggnog-mapper_v2.1.11

		"""



