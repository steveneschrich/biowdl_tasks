version 1.0

# Copyright (c) 2017 Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

task Predict {
    input {
        File bed
        File bim
        File fam
        File model
        String outputPath
        Int K = 8
        Int CVE = 5 #number of folds for CV error calculation; default = 5

        String memory = "8GiB"
        String dockerImage = "quay.io/biocontainers/admixture:1.3.0--0"
    }

    String sample = basename(bed, ".bed")
    
#reference.2.P study.2.P.in
#${PIN_DIR}/${PIN_FILE8} 
    # The naming is strict - the input file should be "sample.bed" and
    # the model must be "sample.K.P.in".
    command <<<
        set -e
        # Add model file with the correct name for admixture
        mkdir -p "$(dirname ~{outputPath})"
        cp ~{model} ~{sample}.~{K}.P.in
        cp ~{fam} ~{sample}.fam

        # Run admixture to predict (model filename is inferred).
        admixture \
            -P ~{bed} \
            ~{K} \
            --cv=~{CVE}
        
        # Do some cleaning up of the result file.
        outputfile="~{sample}.~{K}.Q.tsv"

        printf "ID" > $outputfile
        for q in $(seq 1 ~{K}); do printf "\tQ$q" >>$outputfile;done
        printf "\n" >> $outputfile

        # awk magic
        # - We start by setting the output field separator as tab (tab-delimited output)
        # - When NR==FNR is a conditional for lines from the first file only
        # - In the first file, we store the first field as a cache (out), indexed by line number
        # - In the second file, $1=$1 reconsitutes the input line with OFS (here a \t).
        # - We print out the cached field from the first file then the second file (with tab delimiters)
        awk 'BEGIN {OFS="\t"} NR==FNR {out[FNR]=$1;next} {$1=$1; printf "%s\t%s\n", out[FNR], $0}' \
            ~{sample}.fam ~{sample}.~{K}.Q >> $outputfile

    >>>

    output {
        File qFile = "~{sample}.~{K}.Q.tsv"
    }

    runtime {
        memory: memory
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        
        outputPath: {description: "The location the output bed file should be written to.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        qFile: {description: "Q file with admixture contents."}
    }
}

