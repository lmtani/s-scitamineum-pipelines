version development-1.1

task MakeBedFromFai {
    input {
        File fai
    }

    String outname = basename(fai, ".fai") + ".bed"

    command <<<
        python <<CODE

        import pandas as pd

        fai_file = "~{fai}"
        fai = pd.read_csv(fai_file, sep='\t', header=None)
        fai.columns = ['Chromosome', 'Length', 'Offset', 'Linebases', 'Linewidth']

        bed = fai[['Chromosome', 'Length']]
        bed["Start"] = 0

        bed[["Chromosome", "Start", "Length"]].to_csv("~{outname}", sep='\t', index=False, header=False)

        CODE
    >>>

    runtime {
        docker: "amancevice/pandas:slim-2.2.1"
    }

    output {
        File bed = outname
    }
}