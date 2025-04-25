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

# Use bbmerge.sh for detecting adapters
task DetectAdapter {
    input {
        File read1
        File? read2
        String outputPath = "."
        Int cores = 4
        String memory = "5GiB"
        Int timeMinutes = 20
        String dockerImage = "quay.io/biocontainers/bbmap:39.19--he5f24ec_0"


    }

    # Extract filestem ending at R1 (for read1) for pe result.
    String filestem = sub(basename(read1),"(\.R1)?(\.fq)?(\.fastq)?(\.gz)?", "")
    String adaptersDetectedFile = outputPath + "/" + filestem + ".bbmap_adapters.txt"

    command <<<
        set -e
        
        bbmerge.sh \
            ~{if defined(read2) then "-in1=" + read1 else "-in=" + read1} \
            ~{if defined(read2) then "-in2=" + read2 else ""} \
            outa=~{adaptersDetectedFile}
    >>>

    output{
        File detectedAdapters = adaptersDetectedFile
    }

    runtime {
        cpu: cores
        memory: memory
        time_minutes: timeMinutes
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        read1: {description: "The first or single end fastq file to be run through cutadapt.", category: "required"}
        read2: {description: "An optional second end fastq file to be run through cutadapt.", category: "common"}
        cores: {description: "The number of cores to use.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        timeMinutes: {description: "The maximum amount of time the job will run in minutes.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        detectedAdapters: {description: "Detected adapters for fastq read pair."}
    }
}
