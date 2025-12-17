#!/usr/bin/env nextflow

process DOWNLOAD_FTP_FILE {
    label 'process_medium'

    input:
    tuple val(sample_id), val(ftp)

    output:
    tuple val(sample_id), path('*.fastq.gz'), emit: fastq

    script:
    """
    wget -O ${sample_id}.fastq.gz ${ftp}
    """
}