#!/usr/bin/env nextflow

process FASTQC {
    label 'process_medium'
    container 'ghcr.io/bf528/fastqc:latest'
    publishDir params.outdir
    
    input:
    tuple val(sample_id), path(reads)


    output:
    path("*_fastqc.html"), emit: html
    tuple val(sample_id), path("*_fastqc.zip"), emit: zip
    tuple val(sample_id), path(reads), emit: reads

    script:
    """
    fastqc ${reads}
    """

    stub:
    """
    touch ${sample_id}_fastqc.zip
    touch ${sample_id}_fastqc.html
    """
}