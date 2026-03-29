#!/usr/bin/env nextflow

process CALCULATE_TSS_ENRICHMENT {

    label 'process_medium'
    container 'ghcr.io/bf528/deeptools:latest'
    publishDir "${params.outdir}/tss_enrichment", mode:'copy'

    input:
    tuple val(celltype), path(matrix)

    output:
    tuple val(celltype), path("${celltype}_tss_enrichment.txt")

    script:
    """
    python3 ${projectDir}/bin/tss_enrichment.py \
        --matrix ${matrix} \
        --celltype ${celltype} \
        --output ${celltype}_tss_enrichment.txt
    """

    stub:
    """
    echo -e "Sample\\tTSS_Enrichment\\tTSS_Signal\\tBackground_Signal" > ${celltype}_tss_enrichment.txt
    echo -e "${celltype}_sample1\\t10.5\\t25.3\\t2.4" >> ${celltype}_tss_enrichment.txt
    echo -e "${celltype}_sample2\\t11.2\\t26.1\\t2.3" >> ${celltype}_tss_enrichment.txt
    """
}
