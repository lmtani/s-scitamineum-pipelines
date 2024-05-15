version 1.1

import "structs.wdl"
import "tasks/bcftools_consensus.wdl"
import "tasks/proovframe.wdl"
import "tasks/hypo.wdl"
import "subworkflows/IlluminaGenotyping.wdl" as illumina_genotyping
import "subworkflows/AssemblyAssessment.wdl" as assembly_assessment


workflow AssemblyPolish {
  input {

    PairedEndExperiment illumina_dna_experiments  # Suport only one experiment
    File reference_genome
    String small_variants_genotyper = "GATK"
    Int sequencing_coverage
    String genome_size  # 20m, 200m, 2g
    Int threads

    String output_name

    File busco_dataset
    File proteins
    String lineage_name
  }


  # Creating alignment for short reads
  call illumina_genotyping.IlluminaGenotyping {
    input:
      illumina_dna_experiments = [illumina_dna_experiments],  # make compatible by passing list
      reference_genome = reference_genome,
      small_variants_genotyper = small_variants_genotyper,
  }


  Array[File] r1 = []
  Array[File] r2 = []
  scatter (pair in illumina_dna_experiments.fastq_pairs) {
    File r1_ = pair.r1
    File r2_ = pair.r2
  }
  Array[File] reads_1 = select_all(flatten([r1, r1_]))
  Array[File] reads_2 = select_all(flatten([r2, r2_]))

  # Polish with Hypo
  call hypo.Hypo {
    input:
      reads=flatten([reads_1, reads_2]),
      alignment=IlluminaGenotyping.alignments[0],
      alignment_index=IlluminaGenotyping.alignment_indices[0],
      reference_draft=reference_genome,
      coverage=sequencing_coverage,
      genome_size=genome_size,
      threads=threads,
  }

  call proovframe.proovframe as Proovframe {
    input:
      proteins=proteins,
      sequences=Hypo.polished,
      outname=output_name,
  }

  call illumina_genotyping.IlluminaGenotyping  as second_genotyping{
    input:
      illumina_dna_experiments = [illumina_dna_experiments],
      reference_genome = Proovframe.fixed_sequence,
      small_variants_genotyper = small_variants_genotyper,
  }

  call bcftools_consensus.Consensus as final_consensus {
    input:
      basename = output_name,
      fasta = Proovframe.fixed_sequence,
      variants = second_genotyping.variants[0],
  }

    # Need only new alignment. Conveniente use Genotyping pipeline because of reports
  call illumina_genotyping.IlluminaGenotyping  as third_genotyping{
    input:
      illumina_dna_experiments = [illumina_dna_experiments],
      reference_genome = final_consensus.consensus,
      small_variants_genotyper = small_variants_genotyper,
  }

  # Assessing
  call assembly_assessment.AssemblyAssesment {
    input:
      genome = final_consensus.consensus,
      busco_dataset = busco_dataset,
      lineage_name = lineage_name,
  }

  output {
    File consensus = final_consensus.consensus
    File report = third_genotyping.multiqc_report
    File report_raw = third_genotyping.multiqc_raw_report
    File alignment = third_genotyping.alignments[0]
    File alignment_idx = third_genotyping.alignment_indices[0]
    File variants = third_genotyping.variants[0]
    File variants_idx = third_genotyping.variant_indices[0]
    Array[File] busco_genome = AssemblyAssesment.genome_outputs
    Array[File]? busco_proteins = AssemblyAssesment.protein_outputs
  }
}
