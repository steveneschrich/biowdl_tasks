version 1.0

#' SnapAlignerPaired
#'
#' @description Genomic alignment of paired fastqs to a reference genome using the SNAP aligner
#' 
#' @return The aligned input sequence in the form of a bam file (`.bam`) and bam index file (`.bam.bai`).
#'
#' @details
#' The snap aligner takes paired reads in the form of fastq files and aligns them to a reference. The
#' results are returned as a bam and bam.bai file.
#'
#' Alignment is a resource-intensive task so do keep an eye on memory requirements and disk space requirements.
#' Jobs often fail due to insufficient resources.
#'
#' The reference file deserves a special note. There are a variety of ways to introduce the reference genome. Here,
#' since we are using docker containers, we use a special variable `dockerVolumes` to mount an external volume in the
#' container. The `reference_genome` string indicates the path in the container to the snap index directory. Have a
#' look at the https://github.com/steveneschrich/wdl-refdata for workflows to construct this external volume.
#'
task SnapAlignerPaired {

    input {
        File fq1
        File fq2
        String indexDirectory
        String outputFilestem
        String outputType = "wes"

        Int cpu = 16
        String dockerImage = "quay.io/biocontainers/snap-aligner:2.0.1--hd03093a_1"
        String dockerVolumes = "data/snap-hs37d5.squashfs:/snap-hs37d5:image-src=/"
        String memory = "8G"
        Int timeMinutes = 8640
    }

    command <<<
        snap-aligner \
            paired \
            ~{indexDirectory} \
            ~{fq1} \
            ~{fq2} \
            -t ~{cpu} \
            -xf 2.0 \
            -so \
            -R '@RG\tID:${outputFilestem}\tSM:${outputFilestem}\tPL:ILLUMINA\tLB:${outputFilestem}_${outputType}' \
            -o ~{outputFilestem}.bam
    >>>
    output {
        File bam = outputFilestem + ".bam"
        File bai = outputFilestem + ".bam.bai"
    }
    runtime {
        memory: memory
        cpu: cpu
        time_minutes: timeMinutes
        docker: dockerImage
        docker_volumes: dockerVolumes
    }
}

#' SnapIndexer
#'
#' @description Generates index files that are needed by the snap-aligner, based on a reference fasta.
#'
#' @return `snap_index` - a tar.gz tarball of the index files. This keeps downstream references simpler,
#'  since it is a single file. But do note it is a very large tarball.
#'
#' @details
#' This task is designed to generate the needed index files for a snap alignment to run. The aligner
#' needs a specific genome to align to, therefore this indexer works on the level of a specific genome
#' as provided by a fasta file.
#'
#' This requires a lot of time/power to generate! As you might expect, working with a large genome can
#' take some resources to index. Moreover, the index itself is very large (human version, 39GB) so plan
#' accordingly.
#' 
#' The output of this task is a tarball of the index files (in a directory called snap_index). While
#' it is possible to extract to a reference filesystem, one can have a look at the 'mksquashfs' task
#' which tries to construct a `squashfs` filesystem file that can be mounted in containers directly.
task SnapIndexer {

    input {
        File inputFasta
        Int numThreads = 16
        String dockerImage = "quay.io/biocontainers/snap-aligner:2.0.1--hd03093a_1"
        String memory = "48G"
        Int timeMinutes = 8640
        String outputDirectory = "snap_2.0.1"
    }

    command <<<
        snap-aligner \
            index \
            ~{inputFasta} \
            ~{outputDirectory} \
            -t~{numThreads} 
        
        # Create tarball of index for downstream usage
        (cd ~{outputDirectory} && tar czf ../~{outputDirectory}.tar.gz .)

    >>>

    output {
        File snapIndex = "~{outputDirectory}.tar.gz"
    }
    runtime {
        memory: memory
        cpu: numThreads
        time_minutes: timeMinutes
        docker: dockerImage 
    }
}
