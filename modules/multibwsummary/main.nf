#!/usr/bin/env nextflow

process MULTIBWSUMMARY {

    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/bwsummary", mode:'copy'

    input:
    path(bigwig_file)

    output:
    path("all_bigwig_info.npz"), emit: npz
    path("all_bigwig_info.tab"), emit: tab

    script:
    """
    multiBigwigSummary bins \
        -b ${bigwig_file} \
        -o all_bigwig_info.npz \
        --outRawCounts all_bigwig_info.tab
    """

    stub:
    """
    touch all_bigwig_info.nps
    """

}