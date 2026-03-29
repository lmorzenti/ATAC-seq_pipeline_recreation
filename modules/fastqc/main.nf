#!/usr/bin/env nextflow 

process FASTQC {
    
    label 'process_low'
    container 'ghcr.io/bf528/fastqc:latest'
    publishDir "${params.outdir}/quality_check", mode: 'copy'

    input:
    tuple val(sample_name), path(fastqfile) 

    output:
    tuple val(sample_name), path('*.zip'), emit: zip
    tuple val(sample_name), path('*.html'), emit: html

    script:
    """
    fastqc \
        ${fastqfile} \
        -t ${task.cpus}
    """

    stub:
    """
    touch ${sample_name}_fastqc.zip
    touch ${sample_name}_fastqc.html
    """
}