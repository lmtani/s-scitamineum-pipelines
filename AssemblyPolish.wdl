version development-1.1

import "structs.wdl"
import "tasks/bcftools_consensus.wdl"

import "subworkflows/IlluminaGenotyping.wdl" as illumina_genotyping
import "subworkflows/AssemblyAssessment.wdl" as assembly_assessment


workflow AssemblyPolish {
  input {
    PairedEndExperiment illumina_dna_experiments  # Suport only one experiment
    File reference_genome
    String output_name
    File busco_dataset
    String lineage_name
    Int threads = 8
  }


  call illumina_genotyping.IlluminaGenotyping {
    input:
      illumina_dna_experiments = [illumina_dna_experiments],
      reference_genome = reference_genome,
      threads=threads,
  }


  call bcftools_consensus.Consensus {
    input:
      basename = output_name,
      fasta = reference_genome,
      variants = IlluminaGenotyping.variants[0],
  }

  # Need only new alignment. Conveniente use Genotyping pipeline because of reports
  call illumina_genotyping.IlluminaGenotyping  as final {
    input:
      illumina_dna_experiments = [illumina_dna_experiments],
      reference_genome = Consensus.consensus,
      threads=threads,
  }

  # Assessing
  call assembly_assessment.AssemblyAssesment {
    input:
      genome = Consensus.consensus,
      busco_dataset = busco_dataset,
      lineage_name = lineage_name,
  }

  output {
    File consensus = Consensus.consensus
    File report = final.multiqc_report
    File report_raw = final.multiqc_raw_report
    File alignment = final.alignments[0]
    File alignment_idx = final.alignment_indices[0]
    File variants = final.variants[0]
    File variants_idx = final.variant_indices[0]
    Array[File] busco_genome = AssemblyAssesment.genome_outputs
    Array[File]? busco_proteins = AssemblyAssesment.protein_outputs
  }
}
