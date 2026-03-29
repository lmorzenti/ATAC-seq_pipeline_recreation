#!/usr/bin/env nextflow

process BOWTIE2_ALIGN {

    label 'process_medium'
    container 'ghcr.io/bf528/bowtie2:latest'
    publishDir "${params.outdir}/alignment", mode: 'copy'

    input:
    tuple val(sample_name), path(trimmed_reads)
    path(index)
    val(index_name)

    output:
    tuple val(sample_name), path("${sample_name}.bam"), emit: bam

    script:
    """
    bowtie2 \
        --very-sensitive \
        -p ${task.cpus} \
        -x ${index}/${index_name} \
        -U ${trimmed_reads} | samtools view -bS - > ${sample_name}.bam
    """

    stub:
    """
    touch ${sample_name}.bam
    """

}