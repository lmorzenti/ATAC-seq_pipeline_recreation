#!/usr/bin/env nextflow

process BOWTIE2_ALIGN {
    label 'process_high'
    container 'ghcr.io/bf528/bowtie2:latest'
    publishDir params.outdir
    
    input:
    //from fastqc
    tuple val(sample_id), path(reads)
    //from bowtie2 index
    path(index)
    val(index_name)

    output:
    tuple val(sample_id), path("${sample_id}.bam"), emit: bam

    script:
    """
    bowtie2 -p ${task.cpus} -x ${index}/${index_name} -U ${reads} | samtools view -bS - > ${sample_id}.bam
    """

    stub:
    """
    touch ${sample_id}.bam
    """
}