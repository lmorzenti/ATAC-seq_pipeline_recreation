#!/usr/bin/env nextflow

process CALCULATE_FRIP {

    label 'process_medium'
    container 'ghcr.io/bf528/bedtools_samtools:latest'
    publishDir "${params.outdir}/frip", mode: 'copy'
    
    input:
    tuple val(sample_name), path(bam), path(peaks)

    output:
    path("${sample_name}_frip.txt"), emit: txt
    path("${sample_name}_frip.csv"), emit: csv

    script:
    """
    # Count the total amount of reads
    total_reads=\$(samtools view -c -F 260 ${bam})

    # Count the reads found in each peak
    reads_in_peaks=\$(bedtools intersect -a ${bam} -b ${peaks} -u -f 0.20 | samtools view -c)
    
    # Calculate frip
    frip=\$(echo "\$reads_in_peaks \$total_reads" | awk '{printf "%.4f", \$1/\$2}')
    

    # Save the results in a txt and csv file for later analysis
    echo "Sample: ${sample_name}" > ${sample_name}_frip.txt
    echo "Total reads: \$total_reads" >> ${sample_name}_frip.txt
    echo "Reads in peaks: \$reads_in_peaks" >> ${sample_name}_frip.txt
    echo "FRiP: \$frip" >> ${sample_name}_frip.txt
    
    echo "${sample_name},\$total_reads,\$reads_in_peaks,\$frip" > ${sample_name}_frip.csv
    """

    stub:
    """
    touch ${sample_name}_frip.txt
    touch ${sample_name}_frip.csv
    """



}