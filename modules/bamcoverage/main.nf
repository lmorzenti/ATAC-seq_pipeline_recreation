#!/usr/bin/env nextflow

process BAMCOVERAGE {

    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/bigwigs", mode:'copy'

    input:
    tuple val(sample_name), path(sorted_bam), path(bai)

    output:
    tuple val(sample_name), path('*.bw')

    script:
    """
    bamCoverage \
    -b ${sorted_bam} \
    -o ${sample_name}.bw \
    -p ${task.cpus}
    """

    stub:
    """
    touch ${sample_name}.bw
    """

}