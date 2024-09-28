version development-1.1

import "structs.wdl"
import "tasks/fungap.wdl"

workflow MakeGenePredictions {
    input {
        File genome
        FastqPair rna
        String augustus_species
        String busco_dataset
        File sister_proteome
        Int num_cores
    }

    call fungap.PredictGenes {
        input:
            genome = genome,
            rna_reads_r1 = rna.r1,
            rna_reads_r2 = rna.r2,
            augustus_species = augustus_species,
            busco_dataset = busco_dataset,
            sister_proteome = sister_proteome,
            num_cores = num_cores
    }

    output {
        File genes_gff = PredictGenes.genes_gff
        File proteins_fasta = PredictGenes.proteins_fasta
        File transcripts_fasta = PredictGenes.transcripts_fasta
    }
}
