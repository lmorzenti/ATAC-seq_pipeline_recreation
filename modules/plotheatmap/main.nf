#!/usr/bin/env nextflow

process PLOTHEATMAP {

    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/heatmaps", mode: 'copy'

    input:
    path(matrix)

    output:
    path('*.png')

    script:
    """
    plotHeatmap \
        -m ${matrix} \
        -o ${matrix.baseName}_heatmap.png \
        --sortRegions descend \
        --regionsLabel "Loss" "Gain"
    """

    stub:
    """
    touch heatmap.png
    """

}