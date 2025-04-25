version 1.0

# MIT License
#
# Copyright (c) 2022 Leiden University Medical Center
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

# FastqScreen is a tool for screening fastq files for reads aligning to
# multiple species. This is helpful as a diagnostic if one builds a database
# of all expected species from your lab as well as contaminants commonly seen
# in experiments. Classifying (and filtering) reads based on contamination
# allows for a clearer view of the experimental results.
#
task FastqScreen {
    input {
        File read1
        File read2
        String configFile = "/ref/fastq_screen.conf"
        String outputPath = "."

        String referenceVolume = "reference_dir:/ref"
        String dockerImage = "quay.io/biocontainers/fastq-screen:0.16.0--pl5321hdfd78af_0"
        Int threads = 4
    }
    String filestemRead1 = sub(basename(read1),"(\.fq)?(\.fastq)?(\.gz)?", "")
    String filestemRead2 = sub(basename(read2),"(\.fq)?(\.fastq)?(\.gz)?", "")
    command <<<

        fastq_screen \
            --threads ~{threads} \
            ~{"--conf " + configFile} \
            --outdir ~{outputPath} \
            ~{read1} \
            ~{read2}
    >>>

    output {
        File read1htmlReport = outputPath + "/" + filestemRead1 + "_screen.html"
        File read2htmlReport = outputPath + "/" + filestemRead2 + "_screen.html"
        File read1textReport = outputPath + "/" + filestemRead1 + "_screen.txt"
        File read2textReport = outputPath + "/" + filestemRead2 + "_screen.txt"
        File read1pngReport = outputPath + "/" + filestemRead1 + "_screen.png"
        File read2pngReport = outputPath + "/" + filestemRead2 + "_screen.png"
    }
    runtime {
        cpu: threads
        #memory: memory
        #time_minutes: timeMinutes
        docker: dockerImage
        reference_volume: referenceVolume
    }
    parameter_meta {

    }
}


workflow UnitTest {
    call FastqScreen {
        input:
            read1 = "fqs.1.fastq.gz",
            read2 = "fqs.2.fastq.gz"
    }
}