#!/usr/bin/env nextflow

process PLOTCORRELATION {
    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/plotcorr_full", mode: 'copy'

    input:
    path(bigwig)

    output:
    path("correlation_plot.png")

    script:
    """
    plotCorrelation -in ${bigwig} -c spearman -p heatmap --plotNumbers -o correlation_plot.png
    """
    
    stub:
    """
    touch correlation_plot.png
    """
}