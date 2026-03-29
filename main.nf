//include the tools from here
include {DOWNLOAD} from './modules/download_files'
include {FASTQC} from './modules/fastqc'
include {TRIMMOMATIC} from './modules/trimmomatic'
include {BOWTIE2_BUILD} from './modules/bowtie2_build'
include {BOWTIE2_ALIGN} from './modules/bowtie2_align'
include {REMOVE_MITOCHONDRIAL} from './modules/remove_mitochondrial'
include {SAMTOOLS_SORT} from './modules/samtools_sort'
include {SAMTOOLS_INDEX} from './modules/samtools_index'
include {SAMTOOLS_STAT} from './modules/samtools_stat'
include {MULTIQC} from './modules/multiqc'
include {MACS3_CALLPEAKS} from './modules/macs3_callpeaks'
include {BEDTOOLS_REMOVE} from './modules/bedtools_remove'
include {MERGE_REPLICATE_PEAKS} from './modules/merge_peaks'
include {ANNOTATE} from './modules/annotate'
include {FIND_MOTIFS} from './modules/find_motifs'
include {CALCULATE_FRIP} from './modules/calculate_frip'
include {BAMCOVERAGE} from './modules/bamcoverage'
include {MULTIBWSUMMARY} from './modules/multibwsummary'
include {PLOTCORRELATION} from './modules/plotcorrelation'
include {COMPUTEMATRIX as COMPUTEMATRIX_CDC1} from './modules/computematrix'
include {COMPUTEMATRIX as COMPUTEMATRIX_CDC2} from './modules/computematrix'
include {COMPUTE_TSS_MATRIX as COMPUTE_TSS_MATRIX_CDC1} from './modules/computetssmatrix'
include {COMPUTE_TSS_MATRIX as COMPUTE_TSS_MATRIX_CDC2} from './modules/computetssmatrix'
include {PLOTHEATMAP as PLOTHEATMAP_CDC1} from './modules/plotheatmap'
include {PLOTHEATMAP as PLOTHEATMAP_CDC2} from './modules/plotheatmap'
include {PLOTPROFILE as PLOTPROFILE_CDC1} from './modules/plotprofile'
include {PLOTPROFILE as PLOTPROFILE_CDC2} from './modules/plotprofile'
include {CALCULATE_TSS_ENRICHMENT as CALCULATE_TSS_ENRICHMENT_cDC1} from './modules/tss_enrichment_score'
include {CALCULATE_TSS_ENRICHMENT as CALCULATE_TSS_ENRICHMENT_cDC2} from './modules/tss_enrichment_score'


workflow{
 // Download the data from the publication
  // First, create the tuple that will hold the data
    Channel.fromPath(params.fileaccess)
    | splitCsv( header: true )
    | map{ row -> tuple(row.sample_name, row.ftp) }
    | set{ sample_ch }

  // Second, pass the tuple through the download function
  DOWNLOAD(sample_ch)

 // QC: Compute the sequence quality control on the raw reads
  FASTQC(DOWNLOAD.out)

  // Trim the Adapters from the reads
  TRIMMOMATIC(DOWNLOAD.out, params.adapter_fa)

  // Build the genome
  BOWTIE2_BUILD(params.genome)

  // Align the trimmed reads
  BOWTIE2_ALIGN(TRIMMOMATIC.out.reads, BOWTIE2_BUILD.out.index, BOWTIE2_BUILD.out.index_name)

  // Remove the alignments that align to mitochondrial DNA
  REMOVE_MITOCHONDRIAL(BOWTIE2_ALIGN.out.bam)

  // Sort and Index the genomic reads that no longer have the mitochondrial reads
  SAMTOOLS_SORT(REMOVE_MITOCHONDRIAL.out)
  SAMTOOLS_INDEX(SAMTOOLS_SORT.out)

  // QC: Compute the mapping statistics of the reads for quality control 
  SAMTOOLS_STAT(SAMTOOLS_INDEX.out)

  // Grab all the outputs to combine into a single tuple to pass to multiqc
  FASTQC.out.zip.map { it[1] }.collect()
      .set { fastqc_ch }

  TRIMMOMATIC.out.log.map { it[1] }.collect()
      .set { trim_ch }

  SAMTOOLS_STAT.out.map { it[1] }.collect()
      .set { flagstat_ch }

  fastqc_ch.mix(trim_ch).mix(flagstat_ch).flatten().collect()
      .set { multiqc_ch }

  // QC: Pass the channel through multiqc for a comprehensive quality control
  MULTIQC(multiqc_ch)

  // Call Peaks using MACS3 
  MACS3_CALLPEAKS(SAMTOOLS_INDEX.out)

  // Remove the regions listed in the ucsc blacklist
  BEDTOOLS_REMOVE(MACS3_CALLPEAKS.out, params.blacklist)

  // Create a channel to merge replicate peaks for annotation
    merge_peaks_channel = BEDTOOLS_REMOVE.out
        .map { name, bed -> 
            def celltype = (name =~ /cDC\d/)[0]
            def condition = (name =~ /WT|KO/)[0]
            tuple("${celltype}_${condition}", bed)
        }
        .groupTuple()  // Combine reps within same celltype+condition

  // Actually merge the peaks
  MERGE_REPLICATE_PEAKS(merge_peaks_channel)

  // Annotate the grouped, filtered peaks
  ANNOTATE(MERGE_REPLICATE_PEAKS.out, params.genome, params.gtf)

  // Analysis 1: Find motifs
  FIND_MOTIFS(MERGE_REPLICATE_PEAKS.out, params.genome)

  // ATAC-seq specific quality control #1: Calcluating FRiP // 
  // First, join the bam files and the general peaks into a channel
  SAMTOOLS_SORT.out
    .join(BEDTOOLS_REMOVE.out)
    .set { bam_and_peaks }

  // Calculate frip
  CALCULATE_FRIP(bam_and_peaks)
    
  // Create bigwigs from the bam files 
  BAMCOVERAGE(SAMTOOLS_INDEX.out)

  // Make a single channel that contains only bigwig files
    BAMCOVERAGE.out
      .map { sample, bw -> bw }
      .collect()
      .set { bw_ch }

  // Calculate the average read coverage across fixed-size bins in a matrix
  MULTIBWSUMMARY(bw_ch)

  // Visualize how similar the genome-wide signal is between all samples
  PLOTCORRELATION(MULTIBWSUMMARY.out.npz)

  // Split the BigWigs by cell type
  BAMCOVERAGE.out
        .branch { sample, bw ->
            cDC1: sample.contains('cDC1')
                return tuple(sample, bw)
            cDC2: sample.contains('cDC2')
                return tuple(sample, bw)
     }
        .set { bw_by_celltype }

  // Make each cell type its own channel
    bw_by_celltype.cDC1
        .map { sample, bw -> bw }
        .collect()
        .set { cDC1_bw }

    bw_by_celltype.cDC2
        .map { sample, bw -> bw }
        .collect()
        .set { cDC2_bw }

/// Create 2 CSV files that contain cDC1 and cDC2 files for differntial peak analysis ///
/// Complete Differential Peak Analysis in an R markdown before continuing through the rest of the pipeline ///     

  // Calculate read coverage from the bigwig files centered on the differential peaks
  COMPUTEMATRIX_CDC1('cDC1', cDC1_bw, params.cdc1_lost_peaks, params.cdc1_gained_peaks)
    .set { cDC1_matrix }

  COMPUTEMATRIX_CDC2('cDC2', cDC2_bw, params.cdc2_lost_peaks, params.cdc2_gained_peaks)
    .set { cDC2_matrix }

  // Calculate read coverage from the bigwig files centered on the TSS regions 
  COMPUTE_TSS_MATRIX_CDC1('cDC1', cDC1_bw, params.TSS)
    .set { cDC1_TSS_matrix }
    
  COMPUTE_TSS_MATRIX_CDC2('cDC2', cDC2_bw, params.TSS)
    .set { cDC2_TSS_matrix }

  // Visualize peak matrices as a heatmap 
  PLOTHEATMAP_CDC1(cDC1_matrix.map { celltype, matrix -> matrix })
  PLOTHEATMAP_CDC2(cDC2_matrix.map { celltype, matrix -> matrix })

  // Visualize the TSS matrices as an aggregate line plot
  PLOTPROFILE_CDC1(cDC1_TSS_matrix.map { celltype, matrix -> matrix })
  PLOTPROFILE_CDC2(cDC2_TSS_matrix.map { celltype, matrix -> matrix })

  // ATAC-seq specific quality control #2: TSS Enrichment Score // 
  CALCULATE_TSS_ENRICHMENT_cDC1(cDC1_TSS_matrix)
  CALCULATE_TSS_ENRICHMENT_cDC2(cDC2_TSS_matrix)

}