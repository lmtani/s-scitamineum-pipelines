version 1.1


import "../tasks/deepvariant.wdl"


workflow IlluminaDnaGenotyping {
    input {
        File alignment
        File alignment_index
        File reference
        File reference_index
        File reference_dict
    }

    call deepvariant.DeepVariant {
        input:
            alignment = alignment,
            alignment_index = alignment_index,
            reference = reference,
            reference_index = reference_index,
            model_type="WGS",
        }

    output {
        File vcf = DeepVariant.output_vcf
        File vcf_index = DeepVariant.output_vcf_index
        File html_report = DeepVariant.html
    }
}
