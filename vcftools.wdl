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

task SNPFilter {
    input {
        File inputFile
        File SNPList
        String? outputDir
        
        Int threads = 1
        String memory = "1GiB"
        String dockerImage = "quay.io/biocontainers/vcftools:0.1.15--1"

    }

    command <<<
        set -e
        #mkdir -p "$(dirname ~{outputDir})"
        vcftools \
            --gzvcf ~{inputFile} \
            --recode \
            --snps ~{SNPList} \
            ~{"--out " + outputDir}
    >>>

    output {
        File outputFile = outputDir + ".recode.vcf"
    }
    runtime {
        memory: memory
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        inputFile: {description: "The input gzip vcf file.", category: "required"}
        outputDir: {description: "Output directory path.", category: "required"}
        SNPList: {description: "File with SNPs to filter on.", category: "required"}
        memory: {description: "The amount of memory available to the job.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        outputFile: {description: "VCF output file."}
    }
}

