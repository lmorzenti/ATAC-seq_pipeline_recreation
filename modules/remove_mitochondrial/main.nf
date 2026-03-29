#!/usr/bin/env nextflow 

process REMOVE_MITOCHONDRIAL {
    label 'process_medium'
    container 'ghcr.io/bf528/samtools:latest'
    publishDir "${params.outdir}/bam_no_mito", mode: 'copy'

    input:
    tuple val(sample_name), path(bam)

    output:
    tuple val(sample_name), path("${sample_name}.no_mito.bam")

    script:
    """
    samtools view \
        -@ ${task.cpus} \
        -h ${bam} \
        | grep -v chrM \
        | samtools view -b - > ${sample_name}.no_mito.bam
    """

    stub:
    """
    touch ${sample_name}.no_mito.bam
    """
}