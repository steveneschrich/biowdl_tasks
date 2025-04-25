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

task RSEM {
    input {
        File inputBam
        String sampleName
        String outputDir

        String referenceVolume = "/share/lab_eschrich/reference/fsref/rsem:/ref"
        String referenceDir = "/ref/gencode.v30/gencode.v30"
       

        String strandedness = "reverse"
        Boolean pairedEnd=true
 
        Int nthreads = 6
        String memory = "8GiB"
        Int timeMinutes = 240 #10 + ceil(size(inputBams, "GiB") * 60) FIXME
        String dockerImage = "quay.io/biocontainers/rsem:1.3.3--pl5321h5ca1c30_10"
    }
    
    command <<<
        set -e

        rsem-calculate-expression \
            --num-threads ~{nthreads} \
            --alignments \
            --estimate-rspd \
            --strandedness ~{strandedness} \
            ~{true="--paired-end" false="" pairedEnd} \
            ~{inputBam} \
            ~{referenceDir} \
            ~{sampleName}

        # RSEM only generates information in the working directory, so
        # we move the output to the outputDir directly and symlink to it.
        mkdir -p ~{outputDir}
        if [ -f ~{sampleName}.genes.results ]; then
            mv ~{sampleName}.genes.results ~{outputDir}
            ln -sf ~{outputDir}/~{sampleName}.genes.results .
        fi
        if [ -f ~{sampleName}.isoforms.results ]; then
            mv ~{sampleName}.isoforms.results ~{outputDir}
            ln -sf ~{outputDir}/~{sampleName}.isoforms.results .
        fi

    >>>

    output {
       File isoformResults = sampleName + ".isoforms.results"
       File geneResults = sampleName + ".genes.results"
    }

    runtime {
        cpu: nthreads
        memory: memory
        time_minutes: timeMinutes
        docker: dockerImage
        reference_volume: referenceVolume
    }

    parameter_meta {
       
    }
}
