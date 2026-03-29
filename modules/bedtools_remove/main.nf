#!/usr/bin/env nextflow

process BEDTOOLS_REMOVE {

    label 'process_medium'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir "${params.outdir}/filtered_peaks", mode:'copy'

    input:
    tuple val(sample_name), path(macs3peaks)
    path(blacklist)

    output:
    tuple val(sample_name), path("${sample_name}_filtered.narrowPeak")

    script:
    """
    bedtools intersect \
        -a ${macs3peaks} \
        -b ${blacklist} \
        -v > ${sample_name}_filtered.narrowPeak
    """

    stub:
    """
    touch ${sample_name}_filtered.narrowPeak
    """

}