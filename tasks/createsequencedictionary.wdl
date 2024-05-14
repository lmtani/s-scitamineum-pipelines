version 1.1

task CreateSequenceDictionary {
    input {
        File fasta
    }

    String outname = sub(sub(basename(fasta), ".fna", ""), ".fa", "") + ".dict"

    command <<<
        java -Xmx4000m -jar /usr/gitc/picard.jar CreateSequenceDictionary \
            R=~{fasta} \
            O=~{outname}
    >>>

    runtime {
        docker: "us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.2.4-1469632282"
    }

    output {
        File dict = outname
    }
}
