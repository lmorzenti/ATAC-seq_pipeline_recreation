#!/usr/bin/env nextflow

process BEDTOOLS_MERGE_FINAL {
    label 'process_low'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir "${params.outdir}/peaks", mode: 'copy'
    
    input:
    path(beds)  // Multiple repr_peaks.bed files from BEDTOOLS_REMOVE
    
    output:
    path("consensus_peaks.bed")
    
    script:
    """
    # Create local temp directory
    mkdir -p tmp
    export TMPDIR=\${PWD}/tmp

    # Concatenate all intersected peaks
    cat ${beds} | sort -k1,1 -k2,2n > all_intersected_peaks.bed
    
    # Merge overlapping peaks
    bedtools merge -i all_intersected_peaks.bed > consensus_peaks.bed
    """
}