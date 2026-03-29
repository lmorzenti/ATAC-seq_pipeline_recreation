#!/usr/bin/env nextflow

process SAMTOOLS_STAT {

    label 'process_single'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir "${params.outdir}/flagstat", mode:'copy'


    input:
    tuple val(sample_name), path(bam), path(bai)

    output:
    tuple val(sample_name), path("*.flagstat.txt")

    script:
    """
    samtools flagstat \
        -@ ${task.cpus} ${bam} > ${bam.baseName}.flagstat.txt
    """

    stub:
    """
    touch ${bam}_flagstat.txt
    """
}