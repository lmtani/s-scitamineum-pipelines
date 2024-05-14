version 1.1

task proovframe {
    input {
        File proteins
        File sequences
        String outname
    }

    String out_alg = "~{outname}.tsv"
    String out_seq = "~{outname}.fa"

    command <<<
        set -e
        proovframe map -a ~{proteins} -o ~{out_alg} ~{sequences}
        proovframe fix -o ~{out_seq} ~{sequences} ~{out_alg}
    >>>

    runtime {
        docker: "quay.io/biocontainers/proovframe:0.9.7--hdfd78af_1"
    }

    output {
        File alignments = "~{out_alg}"
        File fixed_sequence = "~{out_seq}"
    }
}
