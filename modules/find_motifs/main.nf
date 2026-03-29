#!/usr/bin/env nextflow

process FIND_MOTIFS { 

    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/findmotifs", mode:'copy'

    input:
    tuple val(group_names), path(grouped_peaks)
    path(genome)

    output:
    tuple val(group_names), path("${group_names}_motifs/")

    script:
    """
    findMotifsGenome.pl \
        ${grouped_peaks} \
        ${genome} \
        ${group_names}_motifs \
        -size 200 \
        -mask \
        -p ${task.cpus}
    """

    stub:
    """
    mkdir ${group_names}_motifs
    """


}