#!/usr/bin/env nextflow

process CREATE_DIFFBIND_SAMPLESHEET {
    label 'process_medium'
    container 'ghcr.io/bf528/biopython:latest'
    publishDir "${params.outdir}/diffbind", mode: 'copy'
    
    input:
    tuple val(cell_type), val(sample_ids), val(conditions), val(replicates), path(bams), path(peaks)
    
    output:
    tuple val(cell_type), path("${cell_type}_diffbind_samplesheet.csv")
    
    script:
    """
    python3 ${projectDir}/bin/create_diffbind_samplesheet.py \\
        ${cell_type} \\
        "${sample_ids.join(',')}" \\
        "${conditions.join(',')}" \\
        "${replicates.join(',')}" \\
        "${bams.join(',')}" \\
        "${peaks.join(',')}"    
    """

}