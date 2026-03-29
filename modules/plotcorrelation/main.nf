#!/usr/bin/env nextflow

process PLOTCORRELATION {

    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/plotcorrelation", mode:'copy'

    input:
    path(bw_npz_file)

    output:
    path("correlation_plot.png")

    script:
    """
    plotCorrelation \
        -in ${bw_npz_file} \
        -c ${params.corrtype} \
        -p heatmap \
        --colorMap BrBG \
        --plotNumbers \
        -o correlation_plot.png
    """

    stub:
    """
    touch correlation_plot.png
    """

}