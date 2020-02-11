version 1.0

import "common.wdl"

task Somatic {
    input {
        File tumorBam
        File tumorBamIndex
        File? normalBam
        File? normalBamIndex
        File referenceFasta
        File referenceFastaFai
        String runDir = "./manta_run"
        File? callRegions
        File? callRegionsIndex
        Boolean exome = false

        Int cores = 1
        Int memoryGb = 4
        String dockerImage = "quay.io/biocontainers/manta:1.4.0--py27_1"
    }

    command {
        configManta.py \
        ~{"--normalBam " + normalBam} \
        ~{"--tumorBam " + tumorBam} \
        --referenceFasta ~{referenceFasta} \
        ~{"--callRegions " + callRegions} \
        --runDir ~{runDir} \
        ~{true="--exome" false="" exome}

        ~{runDir}/runWorkflow.py \
        -m local \
        -j ~{cores} \
        -g ~{memoryGb}
    }

    output {
        File candidateSmallIndelsVcf = runDir + "/results/variants/candidateSmallIndels.vcf.gz"
        File candidateSmallIndelsVcfIndex = runDir + "/results/variants/candidateSmallIndels.vcf.gz.tbi"
        File candidateSVVcf = runDir + "/results/variants/candidateSV.vcf.gz"
        File candidatSVVcfIndex = runDir + "/results/variants/candidateSV.vcf.gz.tbi"
        File tumorSVVcf = if defined(normalBam)
                          then runDir + "/results/variants/somaticSV.vcf.gz"
                          else runDir + "/results/variants/tumorSV.vcf.gz"
        File tumorSVVcfIndex = if defined(normalBam)
                               then runDir + "/results/variants/somaticSV.vcf.gz.tbi"
                               else runDir + "/results/variants/tumorSV.vcf.gz.tbi"
        File? diploidSV = runDir + "/results/variants/diploidSV.vcf.gz"
        File? diploidSVindex = runDir + "/results/variants/diploidSV.vcf.gz.tbi"
    }

    runtime {
        cpu: cores
        memory: "~{memoryGb}G"
        docker: dockerImage
    }

    parameter_meta {
        # inputs
        tumorBam: {description: "The tumor/case sample's BAM file.", category: "required"}
        tumorBamIndex: {description: "The index for the tumor/case sample's BAM file.", category: "required"}
        normalBam: {description: "The normal/control sample's BAM file.", category: "common"}
        normalBamIndex: {description: "The index for the normal/control sample's BAM file.", category: "common"}
        referenceFasta: {description: "The reference fasta file which was also used for mapping.", category: "required"}
        referenceFastaFai: {description: "The index for the reference fasta file.", category: "required"}
        runDir: {description: "The directory to use as run/output directory.", category: "common"}
        callRegions: {description: "The bed file which indicates the regions to operate on.", category: "common"}
        callRegionsIndex: {description: "The index of the bed file which indicates the regions to operate on.", category: "common"}
        exome: {description: "Whether or not the data is from exome sequencing.", category: "common"}
        cores: {description: "The number of cores to use.", category: "advanced"}
        memoryGb: {description: "The amount of memory this job will use in Gigabytes.", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
    }
}

task Germline {
    input {
        File bamFile
        File bamIndex
        File referenceFasta
        File referenceFastaFai
        String runDir
        File? callRegions
        File? callRegionsIndex
        Boolean exome = false

        Int cores = 1
        Int memoryGb = 4
        String dockerImage = "quay.io/biocontainers/manta:1.4.0--py27_1"
    }

    command {
        set -e
        configManta.py \
        ~{"--normalBam " + bamFile} \
        --referenceFasta ~{referenceFasta} \
        ~{"--callRegions " + callRegions} \
        --runDir ~{runDir} \
        ~{true="--exome" false="" exome}

        ~{runDir}/runWorkflow.py \
        -m local \
        -j ~{cores} \
        -g ~{memoryGb}
    }

    output {
        File mantaVCF = runDir + "/results/variants/diploidSV.vcf.gz"
        File mantaVCFindex = runDir + "/results/variants/diploidSV.vcf.gz.tbi"
    }

    runtime {
        cpu: cores
        memory: "~{memoryGb}G"
        docker: dockerImage
    }

    parameter_meta {
        bamFile: {description: "The bam file to process.", category: "required"}
        bamIndex: {description: "The index bam file.", category: "required"}
        referenceFasta: {description: "The reference fasta file also used for mapping.", category: "required"}
        referenceFastaFai: {description: "Fasta index (.fai) file of the reference", category: "required" }
        runDir: {description: "The directory to use as run/output directory.", category: "common"}
        callRegions: {description: "The bed file which indicates the regions to operate on.", category: "common"}
        callRegionsIndex: {description: "The index of the bed file which indicates the regions to operate on.", category: "common"}
        exome: {description: "Whether or not the data is from exome sequencing.", category: "common"}
        cores: {description: "The the number of cores required to run a program", category: "advanced"}
        memoryGb: {description: "The memory required to run the manta", category: "advanced"}
        dockerImage: {description: "The docker image used for this task. Changing this may result in errors which the developers may choose not to address.", category: "advanced"}
    }
}
    
