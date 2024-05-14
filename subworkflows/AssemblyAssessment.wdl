version 1.1

import "../tasks/busco.wdl"

workflow AssemblyAssesment {

    input {
        File genome
        File? proteins
        File busco_dataset
        String lineage_name
    }

    call busco.BUSCO as busco_genome {
        input:
        mode="genome",
        fasta=genome,
        lineage=lineage_name,
        lineage_tar=busco_dataset,
        ncpus=4,
    }

    if (defined(proteins)) {
        File proteins_ = select_first([proteins])
        call busco.BUSCO as busco_proteins {
            input:
            mode="proteins",
            fasta=proteins_,
            lineage=lineage_name,
            lineage_tar=busco_dataset,
            ncpus=4,
        }
    }

    output {
        Array[File]? protein_outputs = busco_proteins.outputs
        Array[File] genome_outputs = busco_genome.outputs
    }
}
