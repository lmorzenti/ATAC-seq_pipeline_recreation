#!/usr/bin/env nextflow

process ANNOTATE {
    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/annotations", mode:'copy'

    input:
    tuple val(sample_id), path(filteredbed)
    path(gtf)
    path(genome)

    output:
    path("${sample_id}_annotated_peaks.txt")

    script:
    """
    annotatePeaks.pl ${filteredbed} ${genome} -gtf ${gtf}  > ${sample_id}_annotated_peaks.txt
    """

    stub:
    """
    touch ${sample_id}_annotated_peaks.txt
    """
}