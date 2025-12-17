#!/usr/bin/env nextflow

process PLOTPROFILE {
    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir params.outdir

    input:
    tuple val(sample_id), path(matrix)

    output:
    path("${sample_id}_signal_coverage.png")

    script:
    """
    plotProfile -m ${matrix} -o ${sample_id}_signal_coverage.png
    """

    stub:
    """
    touch ${sample_id}_signal_coverage.png
    """
}