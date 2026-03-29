#!/usr/bin/env nextflow

process MACS3_CALLPEAKS {

    label 'process_high'
    container 'ghcr.io/bf528/macs3:latest'
    publishDir "${params.outdir}/macs3_peaks", mode: "copy"

    input:
    tuple val(sample_name), path(bam), path(bai)

    output:
    tuple val(sample_name), path("*.narrowPeak") 

    script:
    """
    macs3 callpeak \
        -t ${bam} \
        -f BAM \
        -g mm \
        -n ${sample_name} \
        -q 0.05 \
        --nomodel \
        --keep-dup auto
    """

    stub:
    """
    touch ${sample}_peaks.narrowPeak
    """

}