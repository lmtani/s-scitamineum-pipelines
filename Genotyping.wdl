version 1.1

import "subworkflows/IlluminaGenotyping.wdl" as illumina_genotyping

workflow Genotyping {
    input {
        Array[PairedEndExperiment] illumina_dna_experiments
        File reference_genome
        String fasta_suffix = ".fa"
        In threads
    }

    call illumina_genotyping {
        input:
            illumina_dna_experiments = illumina_dna_experiments,
            reference_genome = reference_genome,
            threads=threads,
    }

    output {
        Array[File] vcf = illumina_genotyping.variants
        Array[File] vcf_index = illumina_genotyping.variant_indices
        Array[File] alignments = illumina_genotyping.alignments
        Array[File] alignment_indices = illumina_genotyping.alignment_indices
        File multiqc_report = illumina_genotyping.multiqc_report
        File multiqc_raw_report = illumina_genotyping.multiqc_raw_report
    }
}
