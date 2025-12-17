#!/usr/bin/env nextflow

process POS2BED {
    label 'process_medium'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir params.outdir

    input:
    tuple val(sample_id), path(foundpeaks)

    output:
    tuple val(sample_id), path("${foundpeaks.baseName}.bed")

    script:
    """
    pos2bed.pl ${foundpeaks} > ${foundpeaks.baseName}.bed
    """

    stub:
    """
    touch ${foundpeaks.baseName}.bed
    """
}

