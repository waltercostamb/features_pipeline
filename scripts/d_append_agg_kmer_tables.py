#!/usr/bin/env python3

'''Makes one table of all the kmer tables
USAGE : /1_scripts/2_CompareKmers/ [1] input_file [2] output_path  '''

### HOUSEKEEPING

import pandas as pd
import sys
import os

### FUNCTION

def merge_kmer_profile(kmer_tables_list):
    '''
    Takes a list with the file paths as input and merges the tables into one dataframe.
    If a kmer is found duplicated, the merging went wrong 
    and the option to stop adding more tables is there.
    '''
    dfs = []  # List to hold dataframes before merging

    # Load and preprocess each table
    for file_name in kmer_tables_list:
        try:
            table = pd.read_csv(f'{file_name}', sep='\t', index_col=0)
            table = table[~table.index.duplicated(keep='first')]
            dfs.append(table)
        except:
            print(f'>> {file_name} had an error')

    # Concatenate dataframes
    merged_df = pd.concat(dfs, axis=1)

    # Group by index and aggregate if needed
    merged_df = merged_df.groupby(merged_df.index).sum()  # Example: Sum values with same index

    return merged_df


if __name__ == '__main__':


    ### INPUT & OUTPUT

    # input_file = '/home/ro35nam/0_data/2_CompareKmers/test_fastQ/gerbil_output/ERR2356284_MERGED_FASTQ.fasta.gz_k{9}.out'
    # input_folder = '/work/groups/VEO/shared_data/rose/salinity/kmer_tables'
    # input_folder = '/Users/roosbrouns/Library/CloudStorage/OneDrive-Friedrich-Schiller-UniversitätJena/Projects/CompareTaxa/0_data/2_Compar
    # input_folder = sys.argv[1]
    file_w_paths = sys.argv[1]
    chunk_name = '_'.join(file_w_paths.split('/')[-1].split('_')[-2:])

    # output_path = '/Users/roosbrouns/Library/CloudStorage/OneDrive-Friedrich-Schiller-UniversitätJena/Projects/CompareTaxa/0_data/2_CompareKmers/k-mers_test'
    # output_path = '/work/groups/VEO/shared_data/rose/salinity'
    output_path = sys.argv[2]
    

    ### RUN

    # kmer_tables = os.listdir(input_folder)

    with open(file_w_paths, "r") as file:
        kmer_tables = [line.strip() for line in file]

    # Create empty the DataFrame
    df = pd.DataFrame()

    df_merged = merge_kmer_profile(kmer_tables)

    # Check for duplicates
    if sum(df_merged.index.duplicated(keep=False)) > 0:
        print(f'> duplicates found in {chunk_name}')
    else:
        pass

    # Replace NaN by 0
    df_merged.fillna(0, inplace=True)

    # Save to file with run-id
    df_merged.to_csv(f'{output_path}/kmer9_profiles_{chunk_name}.tsv', sep='\t')
    # df_filtered.to_csv(f'{output_path}/kmer9_profiles_{threshold}_{chunk_name}-filtered.tsv', sep='\t', index=False)

