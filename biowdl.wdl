version 1.0

# Copyright (c) 2018 Leiden University Medical Center
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

task InputConverter {
    input {
        File samplesheet
        String outputFile = "samplesheet.json"
        # File checking only works when:
        # 1. Paths are absolute
        # 2. When containers have the directory with the files mounted.
        # Therefore this functionality does not work well with cromwell.
        Boolean skipFileCheck=true
        Boolean checkFileMd5sums=false
        Boolean old=false

        String memory = "128MiB"
        Int timeMinutes = 1
        String dockerImage = "quay.io/biocontainers/biowdl-input-converter:0.3.0--pyhdfd78af_0"
    }

    command <<<
        set -e
        mkdir -p "$(dirname ~{outputFile})"
        biowdl-input-converter \
        -o ~{outputFile} \
        ~{true="--skip-file-check" false="" skipFileCheck} \
        ~{true="--check-file-md5sums" false="" checkFileMd5sums} \
        ~{true="--old" false="" old} \
        ~{samplesheet}
    >>>

    output {
        File json = outputFile
    }

    runtime {
        memory: memory
        time_minutes: timeMinutes
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        samplesheet: {description: "The samplesheet to be processed.", category: "required"}
        outputFile: {description: "The location the JSON representation of the samplesheet should be written to.", category: "advanced"}
        skipFileCheck: {description: "Whether or not the existance of the files mentioned in the samplesheet should be checked.", category: "advanced"}
        checkFileMd5sums: {description: "Whether or not the MD5 sums of the files mentioned in the samplesheet should be checked.", category: "advanced"}
        old: {description: "Whether or not the old samplesheet format should be used.", category: "advanced"}
        memory: {description: "The amount of memory needed for the job.", category: "advanced"}
        timeMinutes: {description: "The maximum amount of time the job will run in minutes.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}

        # outputs
        json: {description: "JSON file version of the input sample sheet."}
    }
}

# The goal of this task is to standardize the input fastq files. Specifically, files
# provided in the sample table can be named in whatever way they come in. Which is
# important for reproducibility. Understanding these files in output reports is 
# another story, since the names can collide and be misleading. The sample table
# is the place that this information is documented. 
#
# This task will use the sample table to determine a "standard" naming convention
# for inputs: sample_library_readgroup.R1/2.fastq.gz. This gives us the advantage
# of a flat namespace (no name collisions), but also more consistency in naming.
# To achieve this, we 
# - create a new directory of symlinks (projectDir/data/reads_standardized)
# - create a mapping file from the original filenames
#   - the real path to the files is also included for cases in which the original
#       filenames are themselves symlinks.
# - recreate a sample table with updated source filenames
#
# NOTE: the flag linkRealPath allows you to symlink output files to the resolved
# path of the source file. This is the (common) occurrence of a symlink being used
# as a source file. We can (but not default) follow the source file link to the
# original file, then link our standardized file to the original one.
task standardizeInput {
    input {
        File samplesheet
        String projectDir = "."
        String fastqExtension = "fastq.gz"
        String linkDir = projectDir + "/data/reads_standardized"
        String mappingFile = projectDir + "/data/reads_standardized/fastq_map.csv"
        String outputSamplesheet = projectDir + "/data/standardized_" + basename(samplesheet)
        Boolean linkRealPath = false
    }

    command <<<
        set -e

        # Create the output link directory and mapping file.
        mkdir -p ~{linkDir}
        mkdir -p "$(dirname ~{mappingFile})"

        # linkRealPath indicates whether to symlink to the final resolution of
        # any/all symlinks to data (true) or just to link to what is provided (false).
        LINKPATH=~{true="REALPATH" false="DIRECT" linkRealPath}

        # Create headers for mapping file and sample sheet
        printf "source_read_file,standardized_read_file,dereferenced_original_file\n" > ~{mappingFile}
        head -1 ~{samplesheet} > ~{outputSamplesheet}

        # Get the number of read pairs to standardize
        NLINES=$(wc -l  < ~{samplesheet})

        for n in `seq 2 ${NLINES}`; do
            # We reuse the entry over and over in the loop
            ENTRY=$(head -${n} ~{samplesheet} | tail -1)

            # Get the source R1/R2 pairs
            SRC_R1=$(echo $ENTRY | cut -f4 -d",")
            SRC_R2=$(echo $ENTRY | cut -f6 -d",")
            # Add project directory for fully qualified path
            SRC_R1="~{projectDir}/${SRC_R1}"
            SRC_R2="~{projectDir}/${SRC_R2}"

            # Find the source of the input files (if it is a link)
            REAL_R1=$(realpath $SRC_R1)
            REAL_R2=$(realpath $SRC_R2)

            # For the sake of clarity, check now that all source files exist
            for f in $SRC_R1 $SRC_R2 $REAL_R1 $REAL_R2; do
                if [ ! -s ${f} ]; then
                    echo "ERROR: When standardizing sample input files, we identified a file that" >&2
                    echo "does not exist or is empty. This is usually due to path resolution problems." >&2
                    echo "The sample table {~samplesheet} was used to identify R1/R2 files:" >&2
                    echo "R1: sample sheet entry was ${SRC_R1}; this resolved to ${REAL_R1} real path." >&2
                    echo "R2: sample sheet entry was ${SRC_R2}; this resolved to ${REAL_R2} real path." >&2
                    echo "${f} either did not exist or was empty." >&2
                    exit 1
                fi
            done


            # Build the output filename
            FILEBASE=$(echo $ENTRY | cut -f1,2,3 -d"," --output-delimiter="_")
            TGT_R1="$FILEBASE.R1.~{fastqExtension}"
            TGT_R2="$FILEBASE.R2.~{fastqExtension}"
            # Add full path to file
            TGT_R1="~{linkDir}/${TGT_R1}"
            TGT_R2="~{linkDir}/${TGT_R2}"

            # Update mapping file
            echo "${SRC_R1},${TGT_R1},${REAL_R1}" >> ~{mappingFile}
            echo "${SRC_R2},${TGT_R2},${REAL_R2}" >> ~{mappingFile}

            # Update outputSamplesheet
            OSAMPLE=$(echo $ENTRY | cut -f1-3 -d",")
            OMDSR1=$(echo $ENTRY | cut -f5 -d",")
            OMDSR2=$(echo $ENTRY | cut -f7 -d",")
            echo "$OSAMPLE,$TGT_R1,$OMDSR1,$TGT_R2,$OMDSR2" >> ~{outputSamplesheet}

             # Create a symlink from current file to new name
             if [ "$LINKPATH" = "REALPATH" ]; then
                ln -sf ${REAL_R1} ${TGT_R1}
                ln -sf ${REAL_R2} ${TGT_R2}
             else
                ln -sf ${SRC_R1} ${TGT_R1}
                ln -sf ${SRC_R2} ${TGT_R2}
             fi

        done


    >>>

    output {
        File standardizedFastqMapFile = mappingFile
        File standardizedSamplesheet = outputSamplesheet
    }

}