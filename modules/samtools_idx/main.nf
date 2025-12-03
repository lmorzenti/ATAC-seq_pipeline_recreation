#!/usr/bin/env nextflow

process SAMTOOLS_IDX {
    label 'process_high'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir params.outdir
    
    input:
    tuple val(sample_id), path(sorted_bam)

    output:
    tuple val(sample_id), path(sorted_bam), path("${sample_id}.sorted.bam.bai")

    script:
    """
    samtools index -@ ${task.cpus} ${sample_id}.sorted.bam
    """
    stub:
    """
    touch ${sample_id}.sorted.bam.bai
    """
}