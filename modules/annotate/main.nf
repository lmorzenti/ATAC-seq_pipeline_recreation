#!/usr/bin/env nextflow

process ANNOTATE {

    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/annotations", mode:'copy'

    input:
    tuple val(group_name), path(grouped_peaks)
    path(genome)
    path(gtf)

    output:
    tuple val(group_name), path("${group_name}_annotated.txt")

    script:
    """
    annotatePeaks.pl ${grouped_peaks} ${genome} \
        -gtf ${gtf} > ${group_name}_annotated.txt
    """

    stub:
    """
    touch ${group_name}_annotated.txt
    """

}