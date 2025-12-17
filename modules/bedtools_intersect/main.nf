#!/usr/bin/env nextflow

process BEDTOOLS_INTERSECT {
    label 'process_medium'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir params.outdir, mode: 'copy'
    
    input:
    tuple val(rep1), path(rep1bed), val(rep2), path(rep2bed)

    output:
    path("${rep1bed.baseName}_vs_${rep2bed.baseName}_repr_peaks.bed")

    script:
    """
    bedtools intersect -a ${rep1bed} -b ${rep2bed} -f 0.50 -r > ${rep1bed.baseName}_vs_${rep2bed.baseName}_repr_peaks.bed
    """

    stub:
    """
    touch ${rep1bed.baseName}_vs_${rep2bed.baseName}_repr_peaks.bed
    """
}