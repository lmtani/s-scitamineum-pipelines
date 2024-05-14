version 1.1

# Uses an Illumina DNA alignment to call variants using DeepVariant

import "../tasks/standard.wdl"
import "../tasks/haplotype_caller.wdl"


workflow IlluminaDnaGenotyping {
    input {
        File alignment
        File alignment_index
        File reference
        File reference_index
        File reference_dict
        String small_variant_genotyper = "GATK"
    }

    if (small_variant_genotyper == "DeepVariant") {
        call standard.DeepVariant {
            input:
                alignment = alignment,
                alignment_index = alignment_index,
                reference = reference,
                reference_index = reference_index,
                model_type="WGS",
        }
    }

    if (small_variant_genotyper == "GATK") {
        call haplotype_caller.HaplotypeCaller_GATK4_VCF {
            input:
                input_bam = alignment,
                input_bam_index = alignment_index,
                vcf_basename = basename(alignment),
                ref_dict = reference_dict,
                ref_fasta = reference,
                ref_fasta_index = reference_index,
                ploidy = 1,
                make_gvcf = false,
                make_bamout = true,
                preemptible_tries = 3,
        }
    }

    File output_variants = select_first([DeepVariant.output_vcf, HaplotypeCaller_GATK4_VCF.output_vcf])
    File output_variants_index = select_first([DeepVariant.output_vcf_index, HaplotypeCaller_GATK4_VCF.output_vcf_index])



    output {
        File vcf = output_variants
        File vcf_index = output_variants_index
        File? html_report = DeepVariant.html
        File? gatk_bamout = HaplotypeCaller_GATK4_VCF.bamout
    }
}
