#!/usr/bin/env nextflow

process SAMTOOLS_IDX {
    label 'process_high'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir params.outdir
    
    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path(bam), path("${bam}.bai")

    script:
    """
    samtools index -@ ${task.cpus} ${bam}
    """
    stub:
    """
    touch ${bam}.bai
    """
}