#!/usr/bin/env nextflow

process SAMTOOLS_SORT {

    label 'process_medium'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir "${params.outdir}/samtools_sort_full", mode: 'copy'

    input:
    tuple val(sample_name), path(bamfile)

    output:
    tuple val(sample_name), path("*.sorted.bam")

    script:
    """
    samtools sort \
        -@ ${task.cpus} ${bamfile} > ${sample_name}.sorted.bam
    """

    stub:
    """
    touch ${sample_name}.sorted.bam
    """
}