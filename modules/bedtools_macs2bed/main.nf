#!/usr/bin/env nextflow

process MACS2BED {
    container 'ghcr.io/bf528/bedtools:latest'
    input:
    tuple val(sample_id), path(narrowPeak)

    output:
    tuple val(sample_id), path("${sample_id}.bed")

    script:
    """
    cut -f1-3 ${narrowPeak} > ${sample_id}.bed
    """
}
