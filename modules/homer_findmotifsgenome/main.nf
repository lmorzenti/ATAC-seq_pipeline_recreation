#!/usr/bin/env nextflow

process FIND_MOTIFS_GENOME {
    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/findmotifs", mode:'copy'

    input:
    tuple val(sample_id), path(filteredbed)
    path(genome)

    output:
    tuple val(sample_id), path("homerResults.html")

    script:
    """
    mkdir motifs
    findMotifsGenome.pl ${filteredbed} ${genome} motifs/ -size given -mask -p ${task.cpus}
    """

    stub:
    """
    mkdir motifs
    touch "homerResults.html"
    """
}