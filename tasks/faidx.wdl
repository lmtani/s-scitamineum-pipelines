version 1.1

task Faidx {
    input {
        File fasta
    }

    String outname = basename(fasta) + ".fai"

    command <<<
        samtools faidx --fai-idx ./~{outname} ~{fasta}
    >>>

    runtime {
        docker: "us.gcr.io/broad-gotc-prod/samtools:2.0.0"
    }

    output {
        File fai = "./~{outname}"
    }
}
