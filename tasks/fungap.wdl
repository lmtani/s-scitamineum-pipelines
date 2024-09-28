version development-1.1

task PredictGenes {
    input {
        File genome
        File rna_reads_r1
        File rna_reads_r2
        File sister_proteome  # https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/328/475/GCF_000328475.2_Umaydis521_2.0/GCF_000328475.2_Umaydis521_2.0_protein.faa.gz
        String augustus_species = "ustilago_maydis"
        String busco_dataset = "basidiomycota_odb10"
        Int num_cores
    }

    command <<<
        $FUNGAP_DIR/fungap.py \
            --genome_assembly ~{genome} \
            --trans_read_1 ~{rna_reads_r1} \
            --trans_read_2 ~{rna_reads_r2} \
            --augustus_species ~{augustus_species} \
            --busco_dataset ~{busco_dataset} \
            --sister_proteome ~{sister_proteome} \
            --num_cores ~{num_cores}
    >>>

    runtime {
        docker: "fungap:latest"  # Need to build because gm_key
    }

    output {
        File genes_gff = "fungap_out/fungap_out/fungap_out.gff3"
        File proteins_fasta = "fungap_out/fungap_out/fungap_out.html"
        File transcripts_fasta = "fungap_out/fungap_out/fungap_out_prot.faa"
        File len_dist = "fungap_out/fungap_out/fungap_out_prot_len_dist.png"
        File trans_dist = "fungap_out/fungap_out/fungap_out_trans_len_dist.png"
    }
}
