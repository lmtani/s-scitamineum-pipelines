version 1.0

############################################################
# WDL: liftover_chain.wdl
# Purpose: Given a pair of FASTA assemblies (target/reference and query/old),
#          generate a UCSC .chain file that maps coordinates from the query
#          assembly to the target assembly using LASTZ + UCSC chain/net tools.
#
# Inputs  : target_fasta   - FASTA of the new reference assembly (target)
#           query_fasta    - FASTA of the older/query assembly to be lifted
#
# Output  : chain_file     - final .chain file suitable for UCSC liftOver
#
############################################################

task FastaToTwoBit {
  
  input {
    File fasta
  }

  String base = basename(basename(fasta, ".fasta"), ".fna")

  command <<<
    set -euo pipefail
    faToTwoBit ~{fasta} ~{base}.2bit
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-fatotwobit:482--hdc0a859_0"
    memory: "1G"
    cpu: 1
  }

  output {
    File two_bit = "~{base}.2bit"
  }
}

task TwoBitInfo {
  input {
    File two_bit
  }

  String base = basename(two_bit, ".2bit")
  
  command <<<
    twoBitInfo ~{two_bit} ~{base}.chrom.sizes
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-twobitinfo:482--hdc0a859_0"
    memory: "500M"
    cpu: 1
  }

  output {
    File chrom_sizes = "~{base}.chrom.sizes"
  }
}

task LastzAlign {
  input {
    File target_fasta
    File query_fasta
  }
  
  command <<<
    lastz ~{target_fasta}[multi] ~{query_fasta}[multi] \
          --format=axt \
          --hspthresh=3000 --ydrop=3400 --gapped \
          > align.axt
  >>>

  runtime {
    docker: "quay.io/biocontainers/lastz:1.04.52--h7b50bb2_1"
    memory: "4G"
    cpu: 4
  }

  output {
    File axt = "align.axt"
  }
}


task AxtToPsl {
  input {
    File axt
    File target_sizes
    File query_sizes
  }

  command <<<
    axtToPsl ~{axt} ~{target_sizes} ~{query_sizes} align.psl
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-axttopsl:469--h664eb37_1"
    memory: "500M"
    cpu: 1
  }

  output {
    File psl = "align.psl"
  }
}

task LavToPsl {
  input {
    File lav
  }
  command <<<
    lavToPsl ~{lav} stdout > align.psl
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-lavtopsl:469--h664eb37_1"
    memory: "500M"
    cpu: 1
  }

  output {
    File psl = "align.psl"
  }
}

task AxtChain {
  input {
    File psl
    File target_2bit
    File query_2bit
  }
  command <<<
    axtChain -linearGap=medium -psl ~{psl} ~{target_2bit} ~{query_2bit} chain.raw
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-axtchain:469--h664eb37_1"
    memory: "2G"
    cpu: 2
  }

  output {
    File chain = "chain.raw"
  }
}

task ChainSort {
  input {
    File raw_chain
  }

  command <<<
    chainSort ~{raw_chain} chain.sorted
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-chainsort:469--h664eb37_1"
    memory: "500M"
    cpu: 1
  }

  output {
    File sorted_chain = "chain.sorted"
  }
}

task ChainPreNet {
  input {
    File sorted_chain
    File target_sizes
    File query_sizes
  }

  command <<<
    chainPreNet ~{sorted_chain} ~{target_sizes} ~{query_sizes} chain.pre
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-chainprenet:469--h664eb37_1"
    memory: "1G"
    cpu: 1
  }

  output {
    File pre_chain = "chain.pre"
  }
}

task ChainNet {
  input {
    File pre_chain
    File target_sizes
    File query_sizes
  }
  command <<<
    chainNet ~{pre_chain} ~{target_sizes} ~{query_sizes} net.target /dev/null
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-chainnet:469--h664eb37_1"
    memory: "1G"
    cpu: 1
  }

  output {
    File net = "net.target"
  }
}

task NetChainSubset {
  input {
    File net
    File pre_chain
    String basename
  }

  command <<<
    set -euo pipefail
    netChainSubset ~{net} ~{pre_chain} final.chain && \
    gzip -c final.chain > ~{basename}.final.chain.gz
  >>>

  runtime {
    docker: "quay.io/biocontainers/ucsc-netchainsubset:469--h664eb37_1"
    memory: "500M"
    cpu: 1
  }

  output {
    File chain_final = "~{basename}.final.chain.gz"
  }
}

workflow liftover_chain {
  input {
    File target_fasta
    File query_fasta
  }

  call FastaToTwoBit as TargetTwoBit { input: fasta = target_fasta }
  call FastaToTwoBit as QueryTwoBit  { input: fasta = query_fasta  }

  call TwoBitInfo as TargetInfo { input: two_bit = TargetTwoBit.two_bit }
  call TwoBitInfo as QueryInfo  { input: two_bit = QueryTwoBit.two_bit  }

  call LastzAlign {
    input:
      target_fasta = target_fasta,
      query_fasta  = query_fasta
  }


  call AxtToPsl {
    input:
      axt          = LastzAlign.axt,
      target_sizes = TargetInfo.chrom_sizes,
      query_sizes  = QueryInfo.chrom_sizes
  }
  
  call AxtChain {
    input:
      psl          = AxtToPsl.psl,
      target_2bit  = TargetTwoBit.two_bit,
      query_2bit   = QueryTwoBit.two_bit
  }

  call ChainSort { input: raw_chain = AxtChain.chain }

  call ChainPreNet {
    input:
      sorted_chain = ChainSort.sorted_chain,
      target_sizes = TargetInfo.chrom_sizes,
      query_sizes  = QueryInfo.chrom_sizes
  }

  call ChainNet {
    input:
      pre_chain    = ChainPreNet.pre_chain,
      target_sizes = TargetInfo.chrom_sizes,
      query_sizes  = QueryInfo.chrom_sizes
  }

  String query_basename = basename(query_fasta, ".fna")
  String target_basename = basename(target_fasta, ".fna")

  call NetChainSubset {
    input:
      net       = ChainNet.net,
      pre_chain = ChainPreNet.pre_chain,
      basename  = "~{query_basename}_to_~{target_basename}.chain"
  }

  output {
    File chain_file = NetChainSubset.chain_final
  }
}
