#Developer: Maria Beatriz Walter Costa, waltercostamb@gmail.com
#This pipeline extracts diverse features from bacterial genomes.

# Define the input and output files
K = 9 # Define k length

#Rule checks if output file is already there, if is do not run rule generate_kmers
rule check_kmer_profiles:
    output:
        "kmer9_profiles.tsv"
    run:
        if not os.path.isfile("kmer9_profiles.tsv"):
            open("kmer9_profiles.tsv", "w").close()
        # Create the tmp directory if it doesn't exist
        if not os.path.isdir("tmp"):
            os.mkdir("tmp")

# Rule to generate k-mer counts using Gerbil
rule generate_kmers:
	input:
		genome="input/{sample}.fasta"
	output:
		kmers="output/{sample}_kmer{K}.txt"
	params:
		k=K
	shell:
		r"""
		#Gerbil
	        /home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -e 30GB -t 10 -k {params.k} -l 1 -o fasta {input.genome} temp {output.kmers}

		#Create list of files
        	if [ -f list_kmer{params.k}_files.txt ]; then
           		rm list_kmer{params.k}_files.txt
      	  	fi
	
      	  	ls -lh output/*kmer{params.k}.txt | sed 's/  */\t/g' | cut -f9 | sed 's/output\///g' | sed 's/_kmer{params.k}.txt//g' > list_kmer{params.k}_files.txt
		
		#Run scripts to convert Gerbil output formats
		python3 scripts/d_make_kmer_table.py list_kmer{params.k}_files.txt tmp

        	"""

rule append_agg_kmer_tables:
    input:
        "list_kmer{params.k}_files.txt",
        "output/{sample}_kmer{params.k}.txt"
    output:
        "output/kmer9_profiles.tsv"
    shell:
        r"""
        python3 scripts/d_append_agg_kmer_tables.py list_kmer{params.k}_files.txt output
	rm output/*_kmer9.txt
	rm tmp/*
        rmdir tmp
        """

