#!/usr/bin/env nextflow

process TRIM {
    label 'process_medium'
    container 'ghcr.io/bf528/trimmomatic:latest'
    publishDir params.outdir
    
    input:
    path(adapters)
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_trim.log"), emit: log
    tuple val(sample_id), path("${sample_id}_trimmed.fastq.gz"), emit: reads

    script:
    """
    trimmomatic SE -phred33 ${reads} ${sample_id}_trimmed.fastq.gz ILLUMINACLIP:TruSeq3-SE:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 2>&1 | tee ${sample_id}_trim.log
    """
    // update this command to fit your new sample type please

    //trimmomatic-0.35.jar SE -phred33 ${reads} ${name}_trimmed.fastq.gz ILLUMINACLIP:TruSeq3-SE:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 2>&1 | tee ${name}_trim.log
   
    stub:
    """
    touch ${sample_id}_trim.log
    touch ${sample_id}_trimmed.fastq.gz
    """
}