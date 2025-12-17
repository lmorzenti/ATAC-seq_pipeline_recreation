#!/usr/bin/env nextflow

process REMOVE_MITO {
    label 'process_medium'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir params.outdir
    
    input:
    tuple val(sample_id), path(sorted_bam)

    output:
    tuple val(sample_id), path("${sample_id}_noMT.bam"), emit: nomit

    script:
    """
    samtools view -h ${sorted_bam} | grep -v chrM | samtools view -bS - > ${sample_id}_noMT.bam
    """

    stub:
    """
    touch ${sample_id}_noMT.bam
    """
}