#!/usr/bin/env nextflow 

process DOWNLOAD {

    label 'process_low'
    publishDir "${params.outdir}/raw_reads", mode: 'copy'

    input:
    tuple val(sample_name), val(ftp)

    output:
    tuple val(sample_name), path("${sample_name}.fastq.gz")

    script:
    """
    wget -O ${sample_name}.fastq.gz ${ftp}
    """

    stub:
    """
    touch ${sample_name}.fastq.gz
    """

}