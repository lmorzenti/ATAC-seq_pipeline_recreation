#!/usr/bin/env nextflow 

process TRIMMOMATIC{
    label 'process_low'
    container 'ghcr.io/bf528/trimmomatic:latest'
    publishDir "${params.outdir}/trimmed_reads", mode: 'copy'

    input:
    tuple val(sample_name), file(fastqfile)
    path(adapters)

    output:
    tuple val(sample_name), file("${sample_name}_trimmed.fastq.gz"), emit: reads
    tuple val(sample_name), file("${sample_name}_trimmed.log"), emit:log

    // use the default, single end read command.
    script:
    """
    trimmomatic SE \
        -threads ${task.cpus} \
        -phred33 \
        ${fastqfile} ${sample_name}_trimmed.fastq.gz \
        ILLUMINACLIP:${adapters}:2:30:10 \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2> ${sample_name}_trimmed.log
    """
    stub:
    """
    touch stub_trimmed.fastq.gz
    touch stub_trimmed.log
    """
}