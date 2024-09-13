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
    command {
        set -e
        mkdir -p "$(dirname ~{outputPath})"
        cp ~{model} ~{sample}.~{K}.P.in
        admixture \
            -P ~{bed} \
            ~{K} \
            --cv=~{CVE}

    }

    output {
        File qFile = sample + "." + K + ".Q"
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

