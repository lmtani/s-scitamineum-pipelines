# *Sporisorium scitamineum* Reference Genome

This repository contains all the workflows used to polish and analyze the *S. scitamineum* reference genome first published in the 2015 paper:

> Taniguti LM, Schaker PDC, Benevenuto J, Peters LP, Carvalho G, et al. (2015) Complete Genome Sequence of *Sporisorium scitamineum* and Biotrophic Interaction Transcriptome with Sugarcane. PLOS ONE 10(6): e0129318. https://doi.org/10.1371/journal.pone.0129318

An updated manuscript detailing our polishing and analyses is now available on [bioRxiv](https://www.biorxiv.org/content/10.1101/2025.05.23.649816v1).

Alongside the polishing workflows, this repository also includes additional WDL scripts for comparing public assemblies, batch genotyping, and gene annotation.

## Summary  

- [**AssemblyPolish.wdl**](#assemblypolish)
  Polishes genome assemblies using Illumina reads through variant calling, consensus generation, and assessment with BUSCO.

- [**AssemblyGenePredictions.wdl**](#assemblygenepredictions)
  Annotates genes in a genome assembly using FunGAP, integrating RNA-seq data and a sister proteome.

- [**ComparePublicAssemblies.wdl**](#comparepublicassemblies)
  Fetches, aligns, and merges public genome assemblies from NCBI to compare with a reference genome.  

- [**BatchGenotyping.wdl**](#batchgenotyping)  
  Performs batch genotyping on multiple *S. scitamineum* lineages using Illumina sequencing data.  

## 📂 Repository Structure  

- **inputs/**: Example JSON input files for each workflow.  
- **scripts/**: Additional scripts used in the workflows.  
- **subworkflows/**: Modular subworkflows for genotyping and assessment.  
- **tasks/**: Individual WDL task definitions for various bioinformatics tools.  
- **structs.wdl**: Defines data structures used across workflows.  

## ⚙️ Workflows

### AssemblyPolish

Automates the process of correcting and refining a given reference genome
using high-quality Illumina reads through multiple rounds of variant calling and consensus
generation, followed by quality assessment with BUSCO.

**Key Steps:**

1. **Genotype with Illumina data**: Identifies variants in the reference genome by aligning Illumina
   reads and calling variants (default: DeepVariant).
1. **Generate Consensus**: Incorporates the discovered variants into a new, polished assembly using
   bcftools_consensus.
1. **Re-align & Final Genotyping**: Repeats the genotyping process against the newly polished genome
   to update alignment metrics and variant calls.
1. **Assess Polished Assembly**: Evaluates the quality of the polished genome using BUSCO, providing
   completeness scores and other metrics.

**Inputs:**

- `illumina_dna_experiments`: A single Illumina read set for polishing.
- `reference_genome`: The initial assembly to be polished.
- `output_name`: Naming prefix for generated output files.
- `busco_dataset` / `lineage_name`: BUSCO dataset and lineage information for assembly assessment.
- `threads`: Number of CPU threads for resource-intensive tasks.
  
**Outputs:**

- Final polished `consensus` genome.
- `report` and `report_raw` from the re-alignment step (MultiQC).
- Updated alignment BAM (and index) plus final variants (and index).
- BUSCO results for both the genome and, optionally, protein-based assessments.

This workflow facilitates an iterative approach to assembly polishing by incorporating robust variant
calling and consensus generation, followed by a comprehensive assessment of genome completeness.

---

### ComparePublicAssemblies

Automates the process of downloading multiple genome assemblies from NCBI by accession number,
aligning them to a provided reference genome, and merging the resulting variant calls into a single cohort VCF.

**Key steps:**

1. **FetchNCBI**: Queries the NCBI Assembly database for each accession, retrieving FTP URLs to the genome assemblies.
2. **DownloadAssembly**: Downloads each assembly (in `.fna.gz` format) for further analysis.
3. **genome_alignment**: Uses MUMmer (nucmer) to align each downloaded assembly to a reference genome, generating a VCF.
4. **RenameSampleInVcf**: Renames the VCF sample to match the assembly file’s basename for easier identification.
5. **create_cohort**: Merges the individual VCFs and normalizes them, producing a single, indexed cohort VCF containing
   all variants from the downloaded assemblies.

**Inputs:**

- `Reference` (struct): Contains file paths to the reference genome and any associated protein files (optional usage).
- `Array[String] ncbi_identifiers`: One or more NCBI assembly accession IDs, such as `["GCA_001010845.1"]`.

**Outputs:**

- A merged, normalized `cohort.vcf.gz` file with an accompanying index (`cohort.vcf.gz.tbi`).

This workflow can be used to compare a set of public genomes (specified by their NCBI accession numbers) against
a single reference genome, generating a unified set of variants across all samples for downstream analyses.

---

### BatchGenotyping

Performs batch genotyping on multiple lineages of *Sporisorium scitamineum* using
Illumina sequencing data. It aligns sequencing reads to a reference genome and calls variants
using GATK.

**Key Steps:**

1. **Read Alignment**: Maps Illumina reads to the provided reference genome.
1. **Variant Calling**: Identifies genomic variants across multiple lineages.
1. **Quality Control**: Generates MultiQC reports summarizing alignment and variant-calling metrics.

**Inputs:**

- `Array[PairedEndExperiment] illumina_dna_experiments`: Multiple Illumina read sets.
- `File reference_genome`: The genome to which reads are aligned.
- `String fasta_suffix`: Expected suffix for reference genome files (default: `.fa`).
- `Int threads`: Number of CPU threads for parallel execution.

**Outputs:**

- `vcf` and `vcf_index`: Genotyped variant call files for all samples.
- `alignments` and `alignment_indices`: BAM files and indices for read alignments.
- `multiqc_report` and `multiqc_raw_report`: Summary reports on alignment and variant calling quality.

This workflow is optimized for processing multiple samples in parallel, facilitating comparative
genomic analyses of *S. scitamineum* lineages.

---

### AssemblyGenePredictions

Annotates genes in a provided genome assembly using FunGAP, integrating RNA-seq
data and a sister proteome to improve gene predictions. Due to licensing restrictions, the required
software cannot be distributed via a public Docker image.

**Key Steps:**

1. **Gene Prediction**: Uses FunGAP to annotate genes in the genome.
1. **RNA-seq Integration**: Incorporates RNA-seq reads to improve accuracy.
1. **Protein Homology**: Leverages a sister proteome for additional gene evidence.

**Inputs:**

- `File genome`: The genome assembly to be annotated.
- `FastqPair rna`: Paired-end RNA-seq reads for transcript-based annotation.
- `String augustus_species`: AUGUSTUS species model for gene prediction.
- `String busco_dataset`: BUSCO dataset for assessing annotation quality.
- `File sister_proteome`: Protein sequences from a related species for homology-based predictions.
- `Int num_cores`: Number of CPU cores for computation.

**Outputs:**

- `genes_gff`: GFF file containing predicted gene annotations.
- `proteins_fasta`: FASTA file of predicted protein sequences.
- `transcripts_fasta`: FASTA file of predicted transcript sequences.

This workflow provides a comprehensive gene annotation pipeline, integrating transcriptomics
and protein homology to enhance accuracy. Users must ensure they have a valid FunGAP license
before running the workflow.
