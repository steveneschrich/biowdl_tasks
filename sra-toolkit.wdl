version 1.0

task Prefetch {
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
        File sraCache = "~{accession}/~{accession}.sra"
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
        sraCache: {description: "Cached (prefetched) binary form of NCBI SRA accession."}
    }
}




task FasterqDump {
    input {
        File sraCache
        String accession = basename(sraCache,".sra")
        Int cpu = 6 # Number of threads
        String memory = "16G"
        String dockerImage = "ncbi/sra-tools:3.0.1"
        String dockerShell = "/bin/sh"
    }
    command <<<
        fasterq-dump \
            --threads ~{cpu} \
            -O . \
            ~{sraCache}
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
        sraCache: {description: "The NBCI SRA file from prefetch for extracting fastq data."}
        cpu: {description: "The number of CPUs to allocate for job.", category: "advanced"}
        memory: {description: "The amount of memory this job will use.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
        dockerShell: {description: "The canonical docker image uses /bin/sh, not /bin/bash, so this is overriden for the job.",category: "advanced"}

        # outputs
        fastqs: {description: "A list of fastq files for the SRA file."}
    }
}

workflow DownloadFastq {

    input {
        String accession
        Int cpu = 6
        String memory = "16G"
        String dockerImage = "ncbi/sra-tools:3.0.1"
    }
    call Prefetch as prefetch {
        input:
            accession = accession,
            cpu = 1,
            memory = memory,
            dockerImage = dockerImage
    }

    call FasterqDump as fastqDump {
        input:
            sraCache = prefetch.sraCache,
            cpu = cpu,
            memory = memory,
            dockerImage = dockerImage
    }
    output {
        Array[File] fastqs = fastqDump.fastqs
    }
}