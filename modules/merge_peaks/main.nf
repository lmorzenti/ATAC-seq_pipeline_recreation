#!/usr/bin/env nextflow

process MERGE_REPLICATE_PEAKS {
    
    label 'process_medium'
    container 'ghcr.io/bf528/bedtools:latest'
    publishDir "${params.outdir}/merged_peaks", mode:'copy'
    
    input:
    tuple val(group_name), path(beds)

    output:
    tuple val(group_name), path("${group_name}_merged.bed")

    script:
    """
    # Concatenate all replicate peaks
    cat ${beds.join(' ')} > combined.bed
    
    # Sort combined peaks
    bedtools sort -i combined.bed > combined_sorted.bed
    
    # Actually merge the overlapping peaks
    bedtools merge -i combined_sorted.bed > ${group_name}_merged.bed
    
    # Report how many peaks there were before and after merging
    echo "Original peaks: \$(cat combined.bed | wc -l)" > ${group_name}_merge_stats.txt
    echo "Merged peaks: \$(cat ${group_name}_merged.bed | wc -l)" >> ${group_name}_merge_stats.txt
    """

    stub:
    """
    touch ${group_name}_merged.bed
    """
}