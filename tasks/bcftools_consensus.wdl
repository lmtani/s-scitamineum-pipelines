version development-1.1

task Consensus {
    input {
        String basename
        File fasta
        File variants
    }

    command <<<
        bcftools index --tbi ~{variants}
        bcftools consensus -f ~{fasta} -o ~{basename}.fa ~{variants}
    >>>


    runtime {
        docker: "quay.io/biocontainers/bcftools:1.11--h7c999a4_0"
    }

    output {
        File consensus = "~{basename}.fa"
    }
}
