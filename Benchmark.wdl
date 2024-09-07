version 1.0

# Removido GCA_001243155 -> Muito gap

workflow Benchmark {
    input {
        File reference_sequence
        Array[String] genome_sequences
    }

    call FetchNCBI {
        input:
            accessions = genome_sequences
    }

    scatter (genome in FetchNCBI.assemblies) {

        call DownloadAssembly {
            input:
                fasta_url = genome
        }

        call genome_alignment {
            input:
                reference_genome=reference_sequence,
                other_genome=DownloadAssembly.fasta,
        }

        call RenameSampleInVcf {
            input:
                input_vcf=genome_alignment.vcf,
                output_name=basename(genome_alignment.vcf) + ".gz",
                sample_name=basename(genome, ".fna.gz"),
        }
    }

    call create_cohort {
        input:
            vcf_files=RenameSampleInVcf.output_vcf,
            vcf_indices=RenameSampleInVcf.output_vcf_index
    }
    
    # call identify_hotspots {
    #     input:
    #         variants=create_cohort.vcf
    # }

    # output {
    #     File hotspots = identify_hotspots.vcf
    #     File hotspots_index = identify_hotspots.tbi
    # }
}

task genome_alignment {
    input {
        File reference_genome
        File other_genome
    }

    String basename = basename(other_genome, ".fna.gz")

    command <<<
        set -e
        gunzip -c ~{other_genome} > other_genome.fasta
        nucmer -p ~{basename} ~{reference_genome} other_genome.fasta
        delta-filter -1 ~{basename}.delta > ~{basename}.filtered.delta
        delta2vcf < ~{basename}.filtered.delta > ~{basename}.vcf
        # cleanup and fix delta2vcf. It by default produces GT field = 0
        sed -i 's/0:1:1,2:1:40:2:40/1:1/g' ~{basename}.vcf
        sed -i 's/GT:DP:AD:RO:QR:AO:QA/GT:DP/g' ~{basename}.vcf
        rm other_genome.fasta
    >>>

    runtime {
        docker: "quay.io/biocontainers/mummer4:4.0.0rc1--pl5321hdbdd923_7"
    }

    output {
        File vcf = "~{basename}.vcf"
    }
}

task create_cohort {
    input {
        Array[File] vcf_files
        Array[File] vcf_indices
    }

    command <<<
        set -e
        # merge the VCF files
        bcftools merge ~{sep=" " vcf_files} > cohort.vcf

        # sort, bgzip and index
        bcftools sort cohort.vcf | bgzip -c > cohort.vcf.gz
        tabix -p vcf cohort.vcf.gz
    >>>

    runtime {
        docker: "quay.io/biocontainers/bcftools:1.20--h8b25389_1"
    }

    output {
        File vcf = "cohort.vcf.gz"
        File vcf_index = "cohort.vcf.gz.tbi"
    }
}

# task identify_hotspots {
#     input {
#         File variants
#     }

#     command <<<
#         # identify hotspots

#     >>>

#     runtime {
#         docker: "quay.io/biocontainers/bcftools:1.20--h8b25389_1"
#     }

#     output {
#         File vcf = "hotspots.vcf.gz"
#         File tbi = "hotspots.vcf.gz.tbi"
#     }
# }

task FetchNCBI {
    input {
        Array[String] accessions
        String your_email = "your.email@domain.com"
    }

    command <<<
        python <<CODE
        from Bio import Entrez


        # Always tell NCBI who you are
        Entrez.email = "~{your_email}"

        # The assembly accession number of the genome you want to download
        # accession = "GCA_949128135.1"  # This is an example, replace with your specific accession number


        def get_ftp_url(accession):
            # Fetch the assembly summary
            handle = Entrez.esearch(db="assembly", term=accession)
            id_list = Entrez.read(handle)["IdList"]
            ids = ",".join(id_list)
            ids = id_list[0]
            handle = Entrez.esummary(db="assembly", id=ids)
            record = Entrez.read(handle)
            return record["DocumentSummarySet"]["DocumentSummary"][0]["FtpPath_Stats_rpt"].replace("_assembly_stats.txt", "_genomic.fna.gz")



        # read lines from accessions.txt
        with open("~{write_lines(accessions)}") as f:
            accessions = f.readlines()

        for accession in accessions:
            print(get_ftp_url(accession))
        CODE
    >>>

    runtime {
        cpu: 1
        memory: "2 GB"
        disk: "local-disk 10 HDD"
        docker: "quay.io/biocontainers/biopython:1.75"
    }

    output {
        Array[String] assemblies = read_lines(stdout())
    }
}


task DownloadAssembly {
    input {
        String fasta_url
    }

    String output_name = basename(fasta_url)

    command <<<
        wget ~{fasta_url}
    >>>

    runtime {
        cpu: 1
        memory: "2 GB"
        docker: "quay.io/biocontainers/wget:1.20.1"
        disk: "local-disk 10 HDD"
    }

    output {
        File fasta = output_name
    }
}


task RenameSampleInVcf {
  input {
    File input_vcf
    String output_name
    String sample_name

    Int disk_size = 10
    Int preemptible_tries = 3
  }

  command {
    java -Xms2g -jar /usr/picard/picard.jar \
            RenameSampleInVcf \
             INPUT=~{input_vcf} \
             OUTPUT=~{output_name} \
             CREATE_INDEX=true \
             NEW_SAMPLE_NAME=~{sample_name}
  }
  runtime {
    docker: "us-east1-docker.pkg.dev/genomic-references-127893/broad-institute-images/picard-cloud:2.27.4"
    disks: "local-disk " + disk_size + " HDD"
    memory: "3.5 GiB"
    preemptible: preemptible_tries
  }

  output {
    File output_vcf = output_name
    File output_vcf_index = output_name + ".tbi"
  }
}