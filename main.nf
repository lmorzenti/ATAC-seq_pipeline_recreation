//modules are here:
include {FASTQC} from './modules/fastqc'
include {TRIM} from './modules/trimmomatic'
include {BOWTIE2_BUILD} from './modules/bowtie2_build'
include {BOWTIE2_ALIGN} from './modules/bowtie2_align'
include {SAMTOOLS_SORT} from './modules/samtools_sort'
include {SAMTOOLS_IDX} from './modules/samtools_idx'
include {SAMTOOLS_FLAGSTAT} from './modules/samtools_flagstat'
include {MULTIQC} from './modules/multiqc'


workflow {
    
    Channel.fromPath(params.samplesheet)
    | splitCsv( header: true )
    | map{ row -> tuple(row.name, file(row.path)) }
    | set { read_ch }

    FASTQC( read_ch ) 

    Channel.fromPath(params.samplesheet)
    | splitCsv( header: true )
    | map{ row -> tuple(row.name, file(row.path)) }
    | set { read_ch2 }

    TRIM(params.adapter_fa, read_ch2)

    BOWTIE2_BUILD(params.genome)
    BOWTIE2_ALIGN(FASTQC.out.reads, BOWTIE2_BUILD.out.index, BOWTIE2_BUILD.out.index_name)

    SAMTOOLS_SORT(BOWTIE2_ALIGN.out)
    SAMTOOLS_IDX(SAMTOOLS_SORT.out)

    SAMTOOLS_FLAGSTAT(BOWTIE2_ALIGN.out)

    multiqc_channel = FASTQC.out.zip
       .map { it[1] }
       .mix(TRIM.out.log)
       .mix(SAMTOOLS_FLAGSTAT.out.map { it[1] })
       .collect()
    //

    MULTIQC(multiqc_channel)

  
}
