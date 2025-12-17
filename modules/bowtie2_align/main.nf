#!/usr/bin/env nextflow

process BOWTIE2_ALIGN {
    label 'process_high'
    container 'ghcr.io/bf528/bowtie2:latest'
    
    input:
    tuple val(sample_id), path(reads) 
    path(index)
    val(index_name)

    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: bam

    script:
    """
    bowtie2 --very-sensitive -p ${task.cpus} -x ${index}/${index_name} -U ${reads} | samtools view -bS - > ${sample_id}.bam
    """
    // Comment: adding in the very sensitive is due to the fact that we are working with atac-seq data
    // As this data are single end reads, not paired ends, I did not include other commonly used ATAC-seq specific terms
    // These include the following: --no-mixed --no-discordant -X 2000

    stub:
    """
    touch ${sample_id}.bam
    """
}