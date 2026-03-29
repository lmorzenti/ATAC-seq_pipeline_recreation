#!/usr/bin/env nextflow

process PLOTPROFILE {

    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/plotprofile", mode :'copy'

    input:
    path(matrix)

    output:
    path("${matrix.baseName}_singal_coverage.png")

    script:
    """
    plotProfile \
        -m ${matrix} \
        -o ${matrix.baseName}_singal_coverage.png
    """

    stub:
    """
    touch ${matrix.baseName}_singal_coverage.png
    """

}