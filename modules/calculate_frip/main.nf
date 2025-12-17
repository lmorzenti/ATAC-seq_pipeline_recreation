#!/usr/bin/env nextflow

process CALCULATE_FRIP {
    label 'process_medium'
    container 'ghcr.io/bf528/homer_samtools:latest'
    publishDir "${params.outdir}/frip", mode: 'copy'
  
    input:
    tuple val(sample_id), path(bam), path(peaks)
    
    output:
    tuple val(sample_id), path("${sample_id}_frip.txt"), emit: txt
    path("${sample_id}_frip.csv"), emit: csv
    
    script:
    """
    # Check chromosome names in BAM
    echo "BAM chromosomes:" > ${sample_id}_frip.txt
    samtools view -H ${bam} | grep '@SQ' | head -5 >> ${sample_id}_frip.txt

    # Check chromosome names in peaks
    echo "Peak chromosomes:" >> ${sample_id}_frip.txt
    head -5 ${peaks} >> ${sample_id}_frip.txt

    # Count total aligned reads (exclude unmapped reads with -F 4)
    total=\$(samtools view -c -F 4 ${bam})

    # Count reads overlapping peaks
    reads_in_peaks=\$(bedtools intersect -a ${bam} -b ${peaks} -u | wc -l)

    # Calculate FRiP
    frip=\$(awk "BEGIN {printf \\"%.4f\\", \$reads_in_peaks / \$total}")

    # Output results
    echo "" >> ${sample_id}_frip.txt
    echo "Sample: ${sample_id}" >> ${sample_id}_frip.txt
    echo "Total reads: \$total" >> ${sample_id}_frip.txt
    echo "Reads in peaks: \$reads_in_peaks" >> ${sample_id}_frip.txt
    echo "FRiP score: \$frip" >> ${sample_id}_frip.txt

    echo "${sample_id},\$total,\$reads_in_peaks,\$frip" > ${sample_id}_frip.csv
    """
    
    stub:
    """
    touch ${sample_id}_frip.txt
    touch ${sample_id}_frip.csv
    """
}