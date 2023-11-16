# Define the input and output files
GENOME_FILE = "input/CAADIS000000000.fasta"
KMER_OUTPUT = "output/CAADIS000000000_kmer9.txt"
K = 9 # Define k length

# Rule to generate k-mer counts using Gerbil
rule generate_kmers:
	input:
		genome=GENOME_FILE
	output:
		kmers=KMER_OUTPUT
	params:
		k=K
	shell:
		"/home/groups/VEO/tools/gerbil/v1.12/gerbil/build/gerbil -e 30GB -t 10 -k {params.k} -l 1 -o fasta {input.genome} temp {output.kmers}"

# Define a rule to run the pipeline
rule all:
	input:
		KMER_OUTPUT
