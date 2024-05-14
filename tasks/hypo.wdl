version 1.1

task Hypo {
    input {
        Array[File] reads
        File alignment
        File alignment_index
        File reference_draft
        Int coverage
        String genome_size # e.g. 20m
        File? long_reads_alignment
        File? long_reads_alignment_idx
        Int threads
    }

    String outname = "hypo_" + basename(reference_draft)

    command <<<

        hypo -b ~{alignment} \
             -B ~{long_reads_alignment} \
             -r @~{write_lines(reads)} \
             -d ~{reference_draft} \
             -c ~{coverage} \
             -s ~{genome_size} \
             -o ~{outname} \
             -t ~{threads}
    >>>

    runtime {
        docker: "quay.io/biocontainers/hypo:1.0.3--h9a82719_1"
        cpu: threads
    }

    output {
        File polished = outname
    }
}
