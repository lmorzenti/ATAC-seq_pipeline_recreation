#!/usr/bin/env nextflow

process FINDPEAKS {
    label 'process_high'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir params.outdir

    input:
    tuple val(sample_id), path(rep1read), path(rep2read)

    output:
    tuple val(sample_id), path("${sample_id}_peaks.txt")

    script:
    """
    findPeaks ${rep1read} -style factor -o ${sample_id}_peaks.txt -i ${rep2read}
    """

    stub:
    """
    touch ${sample_id}_peaks.txt
    """
}


