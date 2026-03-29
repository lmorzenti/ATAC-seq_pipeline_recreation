
## ATAC-seq Analysis from "The histone deacetylase HDAC1 controls dendritic cell development and anti-tumor immunity", Fernandes et al., 2024


## Data Source
This project uses ATAC-seq single-end reads from the study by De Sá Fernandes et al. (2024), which examines the role of histone deacetylase HDAC1 in controlling dendritic cell development and anti-tumor immunity. The analysis focuses on chromatin accessibility differences between cDC1 and cDC2 dendritic cell subtypes.

**Publication:** De Sá Fernandes, C., Novoszel, P., Gastaldi, T., Krauß, D., Lang, M., Rica, R., Kutschat, A.P., Holcmann, M., Ellmeier, W., Seruggia, D., Strobl, H., & Sibilia, M. (2024). The histone deacetylase HDAC1 controls dendritic cell development and anti-tumor immunity. *Cell Reports*, 43(6), 114308. https://doi.org/10.1016/j.celrep.2024.114308

**Data:** ATAC-seq data from NCBI GEO, accession code: GSE266584


## Running the Pipeline
```bash
conda activate nextflow_latest
nextflow run main3.nf -profile singularity,cluster,conda
```

This pipeline will download the ATAC-seq single reads that were used in the paper and send them off for preprocessing, peak calling, peak annotation, and motif finding. For further analysis, such as using DiffBind for differential chromatin accessibility analysis, the results of the pipeline should be manually input into two seperate csv files. The DiffBind R-markdown files are created with the assumption that there is a csv file for both of the cell types in the study, cDC1 and cDC2. 

## Deliverables
- Nextflow pipeline
- Analysis report 
- A brief discussion of sequencing quality control results
- A brief discussion of the alignment statistics
- Two ATAC-seq specific QC metrics: TSS enrichment score and Fraction of Reads in Peak (FRiP)
- How many differentially accessible regions the pipeline discovered
- Discussion and figure on enrichment results of the differentially accessible regions
- Discussion and figure on motif enrichment results from the differential peaks
- Recreation of Figure 6a-6f from the original paper
- DiffBind R-markdown files for differential analysis
- README.md

## Citation
Fernandes, Philipp Novoszel, Gastaldi T, Krauß D, Lang M, Rica R, et al. The histone deacetylase HDAC1 controls dendritic cell development and anti-tumor immunity. Cell reports. 2024 Jun 1;43(6):114308–8.



