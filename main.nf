//modules are here:
include {DOWNLOAD_FTP_FILE} from './modules/download_files'
include {FASTQC} from './modules/fastqc'
include {TRIM} from './modules/trimmomatic'
include {BOWTIE2_BUILD} from './modules/bowtie2_build'
include {BOWTIE2_ALIGN} from './modules/bowtie2_align'
include {SAMTOOLS_SORT} from './modules/samtools_sort'
include {SAMTOOLS_IDX} from './modules/samtools_idx'
include {REMOVE_MITO} from './modules/remove_mito'
include {SAMTOOLS_FLAGSTAT} from './modules/samtools_flagstat'
include {MULTIQC} from './modules/multiqc'
include {TAGDIR} from './modules/homer_maketagdir'
include {FINDPEAKS} from './modules/homer_findpeaks'
include {POS2BED} from './modules/homer_pos2bed'
include {ANNOTATE} from './modules/homer_annotatepeaks'
include {FIND_MOTIFS_GENOME} from './modules/homer_findmotifsgenome'
include {BAMCOVERAGE} from './modules/deeptools_bamcoverage'
include {MULTIBWSUMMARY} from './modules/deeptools_multibwsummary'
include {PLOTCORRELATION} from './modules/deeptools_plotcorrelation'
include {COMPUTEMATRIX} from './modules/deeptools_computematrix'
include {PLOTPROFILE} from './modules/deeptools_plotprofile'
include {BEDTOOLS_INTERSECT} from './modules/bedtools_intersect'
include {BEDTOOLS_REMOVE} from './modules/bedtools_remove'
include {CALLPEAKS} from './modules/macs_callpeaks'
include {CREATE_DIFFBIND_SAMPLESHEET} from './modules/diffbind_samplesheet'
include {CALCULATE_FRIP} from './modules/calculate_frip'
include {MACS2BED} from './modules/bedtools_macs2bed'
include {MERGE_REPLICATE_PEAKS} from './modules/merge_peaks'
include {COMPUTEMATRIX as COMPUTEMATRIX_CDC1} from './modules/deeptools_computematrix'
include {COMPUTEMATRIX as COMPUTEMATRIX_CDC2} from './modules/deeptools_computematrix'
include {COMPUTE_TSS_MATRIX as COMPUTE_TSS_MATRIX_CDC1} from './modules/deeptools_computetssmatrix'
include {COMPUTE_TSS_MATRIX as COMPUTE_TSS_MATRIX_CDC2} from './modules/deeptools_computetssmatrix'
include {PLOTHEATMAP as PLOTHEATMAP_CDC1} from './modules/deeptools_plotheatmap'
include {PLOTHEATMAP as PLOTHEATMAP_CDC2} from './modules/deeptools_plotheatmap'
include {PLOTPROFILE as PLOTPROFILE_CDC1} from './modules/deeptools_plotprofile'
include {PLOTPROFILE as PLOTPROFILE_CDC2} from './modules/deeptools_plotprofile'


workflow {

  // set up the tuple that will hold the reads and their names  
    Channel.fromPath(params.samplesheet) 
    | splitCsv( header: true )
    | map{ row -> tuple(row.sample, row.ftp) }
    | set { read_ch }

  // Download the files
    DOWNLOAD_FTP_FILE(read_ch)
  
  // Perform quality checks on the raw reads
    FASTQC(DOWNLOAD_FTP_FILE.out.fastq) 

  // Trim reads to make them better
    TRIM(params.adapter_fa, DOWNLOAD_FTP_FILE.out.fastq)

  // Build the indexing for the genome and align the trimmed reads to the ref genome
    BOWTIE2_BUILD(params.genome)
    BOWTIE2_ALIGN(TRIM.out.reads, BOWTIE2_BUILD.out.index, BOWTIE2_BUILD.out.index_name)

  // Gather information of alignment statistics
    SAMTOOLS_FLAGSTAT(BOWTIE2_ALIGN.out.bam)

  // Map the aligned reads by coordinate, remove reads that align to mitochondrial DNA, and index it
    SAMTOOLS_SORT(BOWTIE2_ALIGN.out)
    REMOVE_MITO(SAMTOOLS_SORT.out)
    SAMTOOLS_IDX(REMOVE_MITO.out.nomit)

  // Also calling peaks from macs3 for a maybe easier time with DiffBind
    CALLPEAKS(SAMTOOLS_IDX.out) 

  // remove blacklisted genes
    BEDTOOLS_REMOVE(CALLPEAKS.out, params.blacklist)

  // atac-seq QC metric 1: FRiP
    SAMTOOLS_SORT.out
      .join(BEDTOOLS_REMOVE.out)
      .view()
      .set { bam_and_peaks }

    CALCULATE_FRIP(bam_and_peaks)

   //merge the peaks
     merged_peaks = BEDTOOLS_REMOVE.out
        .map { name, bed -> 
            def celltype = (name =~ /cDC\d/)[0]
            def condition = (name =~ /WT|KO/)[0]
            tuple("${celltype}_${condition}", bed)
        }
        .groupTuple()  // Combine reps within same celltype+condition
    merged_peaks.view()

    MERGE_REPLICATE_PEAKS(merged_peaks)

  
  // Combine samtool index output with macs3 output and parse sample info to make csv file
    SAMTOOLS_IDX.out
        .join(BEDTOOLS_REMOVE.out)
        .map { sample_id, bam, bai, bed ->
            def matcher = (sample_id =~ /ATAC_(cDC\d+)_(WT|KO)_(\d+)/)
            tuple(
                matcher[0][1],  // cell_type
                sample_id,
                matcher[0][2],  // condition
                matcher[0][3],  // replicate
                bam,
                bed
            )
        }
       .groupTuple(by: 0)
       .set { diffbind_by_celltype }

    diffbind_by_celltype.view()

  // Create separate samplesheets for each cell type
    CREATE_DIFFBIND_SAMPLESHEET(diffbind_by_celltype)

  // Collect all quality control metrics into a channel
    multiqc_channel = FASTQC.out.zip
       .map { it[1] }
       .mix(TRIM.out.log.map { it[1] })
       .mix(SAMTOOLS_FLAGSTAT.out.map { it[1] })
       .collect()
    //

    // Make a readable report of the quality control metric 
    MULTIQC(multiqc_channel)

    // Find some motifs
    FIND_MOTIFS_GENOME(MERGE_REPLICATE_PEAKS.out, params.genome)

    // Annotate differentially accessible peaks
    ANNOTATE(MERGE_REPLICATE_PEAKS.out, params.gtf, params.genome)

    // Make bigwig files for the samples
    BAMCOVERAGE(SAMTOOLS_IDX.out)

    // Make a channel that collects only the bigwigs
    BAMCOVERAGE.out
      .map {sample_id, bw -> bw}
      .collect()
      .set {bigwigs_grouped}

    // Summarize the bigwigs
    MULTIBWSUMMARY(bigwigs_grouped)
    
    // Plot a spearman correlation map
    PLOTCORRELATION(MULTIBWSUMMARY.out)

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
    //COMPUTEMATRIX_CDC1('cDC1', cDC1_bw, params.cdc1_lost_peaks, params.cdc1_gained_peaks)
      //  .set { cDC1_matrix }

    //COMPUTEMATRIX_CDC2('cDC2', cDC2_bw, params.cdc2_lost_peaks, params.cdc2_gained_peaks)
      //  .set { cDC2_matrix }

    //COMPUTE_TSS_MATRIX_CDC1('cDC1', cDC1_bw, params.TSS)
      //  .set { cDC1_TSS_matrix }
    
    //COMPUTE_TSS_MATRIX_CDC2('cDC2', cDC2_bw, params.TSS)
      //  .set { cDC2_TSS_matrix }

    // Plot separately with labels
    //PLOTHEATMAP_CDC1(cDC1_matrix.map { celltype, matrix -> matrix })
    //PLOTHEATMAP_CDC2(cDC2_matrix.map { celltype, matrix -> matrix })
    //PLOTPROFILE_CDC1(cDC1_TSS_matrix.map { celltype, matrix -> matrix })
    //PLOTPROFILE_CDC2(cDC2_TSS_matrix.map { celltype, matrix -> matrix })

  
}
