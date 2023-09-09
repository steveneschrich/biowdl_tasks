version 1.0


task snap_aligner {

    input {
        File fq1
        File fq2
        String ref
        String output_base
        String output_type = "wes"

        Int numThreads = 16
        String dockerImage = "quay.io/biocontainers/snap-aligner:2.0.1--hd03093a_1"
        String dockerMounts = "data/snap-hs37d5.squashfs:/snap-hs37d5:image-src=/"
        String memory = "8G"
        Int time_minutes = 8640
    }

    command <<<
        snap-aligner \
            paired \
            ~{ref} \
            ~{fq1} \
            ~{fq2} \
            -t ~{numThreads} \
            -xf 2.0 \
            -so \
            -R '@RG\tID:${output_base}\tSM:${output_base}\tPL:ILLUMINA\tLB:${output_base}_${output_type}' \
            -o ~{output_base}.bam
    >>>
    output {
        File bam = output_base + ".bam"
        File bai = output_base + ".bam.bai"
    }
    runtime {
        memory: memory
        cpu: numThreads
        time_minutes: time_minutes
        docker: dockerImage
        docker_mounts: dockerMounts
    }
}

#' snap_indexer
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
task snap_indexer {

    input {
        File fa
        Int numThreads = 16
        String dockerImage = "quay.io/biocontainers/snap-aligner:2.0.1--hd03093a_1"
        String memory = "48G"
        Int time_minutes = 8640
        String index_dir = "snap_index"
    }

    command <<<
        snap-aligner \
            index \
            ~{fa} \
            ~{index_dir} \
            -t~{numThreads} 
        
        # Create tarball of index for downstream usage
        tar czf ~{index_dir}.tar.gz ~{index_dir}

    >>>

    output {
        File snap_index = "~{index_dir}.tar.gz"
    }
    runtime {
        memory: memory
        cpu: numThreads
        time_minutes: time_minutes
        docker: dockerImage 
    }
}
