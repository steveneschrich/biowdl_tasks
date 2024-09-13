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

task MakeBed {
    input {
        File vcf
        String outputPath

        String memory = "8GiB"
        String dockerImage = "quay.io/biocontainers/plink:1.90b6.12--heea4ae3_0"
    }

    command {
        set -e
        mkdir -p "$(dirname ~{outputPath})"

        plink \
            --make-bed \
            --vcf ~{vcf} \
            --double-id \
            --out ~{outputPath}

    }

    output {
        File bedFile = outputPath + ".bed"
        File bimFile = outputPath + ".bim"
        File famFile = outputPath + ".fam"
    }

    runtime {
        memory: memory
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        vcf: {description: "A vcf file.", category: "required"}
        outputPath: {description: "The location the output bed file should be written to.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        bedFile: {description: "BED file with vcf contents."}
    }
}

