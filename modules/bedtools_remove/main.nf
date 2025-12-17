#!/usr/bin/env nextflow

process BEDTOOLS_REMOVE {
    label 'process_medium'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir "${params.outdir}/filtered_peaks", mode:'copy'

    input:
    tuple val(sample_id), path(bedfile)
    path(blacklist)

    output:
    tuple val(sample_id), path("${sample_id}_filtered.bed")

    script:
    """
    bedtools subtract -a ${bedfile} -b ${blacklist} > ${sample_id}_filtered.bed
    """

    stub:
    """
    touch ${sample_id}_filtered.bed
    """
}