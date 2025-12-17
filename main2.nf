


// Include your modules here
include {DOWNLOAD} from './modules2/download_files'
include {FASTQC} from './modules2/fastqc'
include {TRIM} from './modules2/trimmomatic'
include {BOWTIE2_BUILD} from './modules2/bowtie2_build'
include {BOWTIE2_ALIGN} from './modules2/bowtie2_align'
include {REMOVE_MITO} from './modules2/remove_mito'
include {SAMTOOLS_SORT} from './modules2/samtools_sort'
include {SAMTOOLS_IDX} from './modules2/samtools_idx'
include {SAMTOOLS_FLAGSTAT} from './modules2/samtools_flagstat'
include {MULTIQC} from './modules2/multiqc'
include {BAMCOVERAGE} from './modules2/deeptools_bamcoverage'
include {MULTIBWSUMMARY} from './modules2/deeptools_multibwsummary'
include {PLOTCORRELATION} from './modules2/deeptools_plotcorrelation'
include {CALLPEAKS} from './modules2/macs3_callpeaks'
include {BEDTOOLS_REMOVE} from './modules2/bedtools_remove'
include {MERGE_REPLICATE_PEAKS} from './modules2/merge_peaks'
include {ANNOTATE} from './modules2/homer_annotatepeaks'
include {COMPUTEMATRIX as COMPUTEMATRIX_CDC1} from './modules2/deeptools_computematrix'
include {COMPUTEMATRIX as COMPUTEMATRIX_CDC2} from './modules2/deeptools_computematrix'
include {COMPUTE_TSS_MATRIX as COMPUTE_TSS_MATRIX_CDC1} from './modules2/deeptools_computetssmatrix'
include {COMPUTE_TSS_MATRIX as COMPUTE_TSS_MATRIX_CDC2} from './modules2/deeptools_computetssmatrix'
include {PLOTHEATMAP as PLOTHEATMAP_CDC1} from './modules2/deeptools_plotheatmap'
include {PLOTHEATMAP as PLOTHEATMAP_CDC2} from './modules2/deeptools_plotheatmap'
include {PLOTPROFILE as PLOTPROFILE_CDC1} from './modules2/deeptools_plotprofile'
include {PLOTPROFILE as PLOTPROFILE_CDC2} from './modules2/deeptools_plotprofile'
include {FIND_MOTIFS_GENOME} from './modules2/homer_findmotifsgenome'
include {CALCULATE_FRIP} from './modules2/calculate_frip'
include {CALCULATE_TSS_ENRICHMENT as CALCULATE_TSS_ENRICHMENT_cDC1} from './modules2/tss_enrichment_score'
include {CALCULATE_TSS_ENRICHMENT as CALCULATE_TSS_ENRICHMENT_cDC2} from './modules2/tss_enrichment_score'

workflow {

    // set up the tuples that will hold the information that will be downloaded
    Channel.fromPath(params.samplesheet)
    | splitCsv( header: true )
    | map{ row -> tuple( row.sample, row.ftp) }
    | view()
    | set { sample_ch }

    // actually download the files from the web
    DOWNLOAD(sample_ch)

    //run quality check on them
    FASTQC(DOWNLOAD.out)

    //trim the reads with adapters
    TRIM(DOWNLOAD.out, params.adapter_fa)

    //build a genome index
    BOWTIE2_BUILD(params.genome)

    //align the trimmed reads to the index
    BOWTIE2_ALIGN(TRIM.out.gz, BOWTIE2_BUILD.out)

    //remove reads that align with mitochondrial DNA from the reads
    REMOVE_MITO(BOWTIE2_ALIGN.out)

    //sort and index the filtered reads
    SAMTOOLS_SORT(REMOVE_MITO.out)
    SAMTOOLS_IDX(SAMTOOLS_SORT.out)

    //do some quality checks on the alignments
    SAMTOOLS_FLAGSTAT(REMOVE_MITO.out)

    //create a channel that grabs all of the data from the qc to run to multiqc
    FASTQC.out.zip.map { it[1] }.collect()
        | set { fastqc_ch }

    TRIM.out.log.map { it[1] }.collect()
        | set { trim_ch }

    SAMTOOLS_FLAGSTAT.out.map { it[1] }.collect()
        | set { flagstat_ch }

    fastqc_ch.mix(trim_ch).mix(flagstat_ch).flatten().collect()
        | set { multiqc_ch }

    MULTIQC(multiqc_ch)

    //create bigwigs
    BAMCOVERAGE(SAMTOOLS_IDX.out)

    //call peaks using Macs3
    CALLPEAKS(SAMTOOLS_SORT.out)

    //remove the blacklisted genes
    BEDTOOLS_REMOVE(CALLPEAKS.out, params.blacklist)

    SAMTOOLS_SORT.out
    .join(BEDTOOLS_REMOVE.out)
    .view()
    .set { bam_and_peaks }

    CALCULATE_FRIP(bam_and_peaks)

    merged_peaks = BEDTOOLS_REMOVE.out
        .map { name, bed -> 
            def celltype = (name =~ /cDC\d/)[0]
            def condition = (name =~ /WT|KO/)[0]
            tuple("${celltype}_${condition}", bed)
        }
        .groupTuple()  // Combine reps within same celltype+condition
    merged_peaks.view()

    MERGE_REPLICATE_PEAKS(merged_peaks)
    
    //ANNOTATE(MERGE_REPLICATE_PEAKS.out, params.genome, params.gtf)
    //FIND_MOTIFS_GENOME(MERGE_REPLICATE_PEAKS.out, params.genome)

    BAMCOVERAGE.out.map { sample, bw -> bw }.collect()
    | set { bw_ch }

    MULTIBWSUMMARY(bw_ch)
    PLOTCORRELATION(MULTIBWSUMMARY.out.npz)

    // Split bigWigs by cell type
    BAMCOVERAGE.out
        .branch { sample, bw ->
            cDC1: sample.contains('cDC1')
                return tuple(sample, bw)
            cDC2: sample.contains('cDC2')
             return tuple(sample, bw)
     }
        .set { bw_by_celltype }

    // Collect bigWigs for each cell type
    bw_by_celltype.cDC1
        .map { sample, bw -> bw }
        .collect()
        .view()
        .set { cDC1_bw }

    bw_by_celltype.cDC2
        .map { sample, bw -> bw }
        .collect()
        .view()
        .set { cDC2_bw }

    // Run compute matrix separately for each cell type
    COMPUTEMATRIX_CDC1('cDC1', cDC1_bw, params.cdc1_lost_peaks, params.cdc1_gained_peaks)
        .set { cDC1_matrix }

    COMPUTEMATRIX_CDC2('cDC2', cDC2_bw, params.cdc2_lost_peaks, params.cdc2_gained_peaks)
        .set { cDC2_matrix }

    COMPUTE_TSS_MATRIX_CDC1('cDC1', cDC1_bw, params.TSS)
        .set { cDC1_TSS_matrix }
    
    COMPUTE_TSS_MATRIX_CDC2('cDC2', cDC2_bw, params.TSS)
        .set { cDC2_TSS_matrix }

    // Plot separately with labels
    PLOTHEATMAP_CDC1(cDC1_matrix.map { celltype, matrix -> matrix })
    PLOTHEATMAP_CDC2(cDC2_matrix.map { celltype, matrix -> matrix })
    PLOTPROFILE_CDC1(cDC1_TSS_matrix.map { celltype, matrix -> matrix })
    PLOTPROFILE_CDC2(cDC2_TSS_matrix.map { celltype, matrix -> matrix })

    // Calculate TSS enrichment scores
    CALCULATE_TSS_ENRICHMENT_cDC1(cDC1_TSS_matrix)
    CALCULATE_TSS_ENRICHMENT_cDC2(cDC2_TSS_matrix)

}