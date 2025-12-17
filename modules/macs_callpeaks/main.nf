process CALLPEAKS {
    label 'process_high'
    conda 'envs/macs3_env.yml'
    publishDir params.outdir, mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path('*narrowPeak')

    script:
    """
    macs3 callpeak -f BAM -t ${bam} -g mm -n ${sample_id} -B -q 0.01 --nomodel --keep-dup all
    """

    stub:
    """
    touch ${sample_id}_peaks.narrowPeak
    """
}