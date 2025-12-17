#!/usr/bin/env nextflow

process BAMCOVERAGE {
    label 'process_high'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir params.outdir
    
    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}.bw")

    script:
    """
    bamCoverage -b ${bam} -o ${sample_id}.bw -p ${task.cpus}
    """

    stub:
    """
    touch ${sample_id}.bw
    """
}