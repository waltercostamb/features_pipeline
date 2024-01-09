# Features pipeline

This is a snakemake pipeline to extract features from bacterial genomes. The final product will be delivered to Swapnil and available for use for the VEO/MGX groups.

According to https://snakemake.readthedocs.io/en/latest/tutorial/tutorial.html#tutorial, "a Snakemake workflow scales without modification from single core workstations and multi-core servers to cluster or batch systems.". Our aim with this pipeline is for users of the VEO/MGX groups to be able to use the pipeline in draco using the power of the slurm cluster.  

Using Snakemake:  

- Submit an sbatch file to slurm, as if the Snakefile would be a usual script
- Allocate a node and run Snakemake directly in the command line, as below. Importantly, some of the software used within Snakefile do not run in the standard node. They require more memory. Therefore, use it in a gpu or fat node.

```
#Allocate a node
salloc -p gpu --gres=gpu:1 
salloc -p gpu -w gpu005

#Activate Snakemake
source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate snakemake_v7.24.0
```

Available features and usage:  

- kmers

```

```

- Gene families

```

```

- GC content

```

```

- Genome size (nt)

```

```

- Genome completeness

```

```

- Pfam domains 
 
```

```

