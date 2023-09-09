version 1.0

task prefetch {
    input {
        String accession
        Int cpu = 1
        String memory = "16G"
        String dockerImage = "ncbi/sra-tools:3.0.1"
        String dockerShell = "/bin/sh"
    }
    command <<<
        prefetch \
            -O . \
            ~{accession}
    >>>

    output {
        # TODO: This should be more robust (file globs)
        File sra_cache = "~{accession}/~{accession}.sra"
    }

    runtime {
        docker: dockerImage
        cpu: cpu
        memory: memory
        docker_shell: dockerShell
    }
    parameter_meta {
        # inputs
        accession: {description: "The NBCI SRA accession number to prefetch for additional processing."}
        cpu: {description: "The number of CPUs to allocate for job.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        dockerShell: {description: "The canonical docker image uses /bin/sh, not /bin/bash, so this is overriden for the job.",category: "advanced"}

        # outputs
        sra_cache: {description: "Cached (prefetched) binary form of NCBI SRA accession."}
    }
}




task fasterq_dump {
    input {
        File sra_cache
        String accession = basename(sra_cache,".sra")
        Int cpu = 6 # Number of threads
        String memory = "16G"
        String dockerImage = "ncbi/sra-tools:3.0.1"
        String dockerShell = "/bin/sh"
    }
    command <<<
        fasterq-dump \
            --threads ~{cpu} \
            -O . \
            ~{sra_cache}
        gzip ~{accession}_*.fastq
    >>>

    output {
        # TODO: This should be more robust (https://jaws-docs.readthedocs.io/en/latest/Tutorials/snippets.html)
        # Use echo *.fastq.gz > output, then read_lines(output) into Array[File]
        Array[File] fastqs = ["~{accession}_1.fastq.gz", "~{accession}_2.fastq.gz"]
    }

    runtime {
        docker: dockerImage
        cpu: cpu
        memory: memory
        docker_shell: dockerShell
    }
    parameter_meta {
        # inputs
        sra_cache: {description: "The NBCI SRA file from prefetch for extracting fastq data."}
        cpu: {description: "The number of CPUs to allocate for job.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        dockerShell: {description: "The canonical docker image uses /bin/sh, not /bin/bash, so this is overriden for the job.",category: "advanced"}

        # outputs
        fastqs: {description: "A list of fastq files for the SRA file."}
    }
}

workflow download_fastq {

    input {
        String accession
        Int cpu = 6
        String memory = "16G"
        String dockerImage = "ncbi/sra-tools:3.0.1"
    }
    call prefetch as prefetch {
        input:
            accession = accession,
            cpu = 1,
            memory = memory,
            dockerImage = dockerImage
    }

    call fasterq_dump as fastq_dump {
        input:
            sra_cache = prefetch.sra_cache,
            cpu = cpu,
            memory = memory,
            dockerImage = dockerImage
    }
    output {
        Array[File] fastqs = fastq_dump.fastqs
    }
}