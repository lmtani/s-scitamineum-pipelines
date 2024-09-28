version development-1.1

import "subworkflows/IlluminaGenotyping.wdl" as illumina_genotyping

workflow Genotyping {
    input {
        Array[PairedEndExperiment] illumina_dna_experiments
        File reference_genome
        String fasta_suffix = ".fa"
        Int threads
    }

    call illumina_genotyping.IlluminaGenotyping {
        input:
            illumina_dna_experiments = illumina_dna_experiments,
            reference_genome = reference_genome,
            threads=threads,
            program="gatk"
    }

    output {
        Array[File] vcf = IlluminaGenotyping.variants
        Array[File] vcf_index = IlluminaGenotyping.variant_indices
        Array[File] alignments = IlluminaGenotyping.alignments
        Array[File] alignment_indices = IlluminaGenotyping.alignment_indices
        File multiqc_report = IlluminaGenotyping.multiqc_report
        File multiqc_raw_report = IlluminaGenotyping.multiqc_raw_report
    }
}
