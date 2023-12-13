#!/usr/bin/env python3

#Developer: Rose Brouns, modified by MB Walter Costa
'''Makes from the fasta outputs with kmers counts from gerbil a table per sample
USAGE : d_make_kmer_table.py [1] input_file'''

### HOUSEKEEPING

import pandas as pd
import sys

### FUNCTION
def split_kmers_fasta(lines):
    '''
    Put the kmers and kmer count from fasta format into 2 separate lists 
    '''
    kmers = []
    counts = []
    for line in lines:
        if line.startswith('>'):
            # Take only number without > from line
            counts.append(int(line[1:]))
        else:
            kmers.append(line)
    
    return(kmers, counts)


if __name__ == '__main__':

    ### INPUT 

    # input_file = defined by Snakemake file, e. g. ID_kmer{K}.txt'
    input_file = sys.argv[1]
    k = input_file.split('_')[1].strip('kmer').strip('.txt')

    ### RUN

    # Read the data from the file
    with open(input_file, 'r') as file:
        data = file.read()

    # Split the data into lines and remove empty lines
    lines = data.split('\n')
    lines = [line.strip() for line in lines if line.strip()]

    # Put the kmers and counts in separte lists
    kmers, counts = split_kmers_fasta(lines)

    # Create the DataFrame
    df = pd.DataFrame({'': kmers, f'{run_id}': counts})

    print(df)

