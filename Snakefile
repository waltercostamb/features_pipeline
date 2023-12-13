#Developer: Maria Beatriz Walter Costa, waltercostamb@gmail.com
#This pipeline extracts diverse features from bacterial genomes.

# Define the input and output files
K = 9 # Define k length

# Rule to generate k-mer counts using Gerbil
rule generate_kmers:
	input:
		genome="input/{sample}.fasta"
	output:
		kmers="output/{sample}_kmer{K}.txt"
	params:
		k=K
	shell:
		"/home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -e 30GB -t 10 -k {K} -l 1 -o fasta {input.genome} temp {output.kmers}"

