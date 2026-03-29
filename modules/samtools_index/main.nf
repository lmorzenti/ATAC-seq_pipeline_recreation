#!/usr/bin/env nextflow

process SAMTOOLS_INDEX {

    label 'process_low'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir "${params.outdir}/indexed", mode: 'copy'

    input:
    tuple val(sample_name), path(sorted_bam)

    output:
    tuple val(sample_name), path(sorted_bam), path("*.sorted.bam.bai"), emit: bai

    script:
    """
    samtools index \
        -@ ${task.cpus} \
        ${sorted_bam}
    """

    stub:
    """
    touch ${sample_name}.sorted.bam.bai
    """
}