#!/usr/bin/env python3
import numpy as np
import gzip
import argparse

def parse_args():
    parser = argparse.ArgumentParser(description='Calculate TSS Enrichment Score')
    parser.add_argument('--matrix', required=True, help='computeMatrix output .gz file')
    parser.add_argument('--celltype', required=True, help='Cell type name')
    parser.add_argument('--output', required=True, help='Output file name')
    parser.add_argument('--bins_per_sample', type=int, default=400, 
                        help='Bins per sample (default 400 for -b 2000 -a 2000 at 10bp resolution)')
    return parser.parse_args()

def load_matrix(matrix_file):
    with gzip.open(matrix_file, 'rt') as f:
        lines = [line for line in f if not line.startswith('@')]
    
    data = []
    for line in lines[1:]:  # skip column header
        values = line.strip().split('\t')[6:]  # skip metadata columns
        data.append([float(x) if x != 'nan' else 0 for x in values])
    
    return np.array(data)

def calculate_enrichment(sample_data, center_start=190, center_end=210, flank_bins=20):
    tss_signal = np.mean(sample_data[:, center_start:center_end])
    flank_signal = np.mean([
        np.mean(sample_data[:, :flank_bins]),
        np.mean(sample_data[:, -flank_bins:])
    ])
    enrichment = tss_signal / flank_signal if flank_signal > 0 else 0
    return enrichment, tss_signal, flank_signal

def main():
    args = parse_args()
    
    data = load_matrix(args.matrix)
    n_total_cols = data.shape[1]
    n_samples = n_total_cols // args.bins_per_sample
    
    print(f"Total columns: {n_total_cols}")
    print(f"Bins per sample: {args.bins_per_sample}")
    print(f"Number of samples: {n_samples}")
    
    with open(args.output, 'w') as out:
        out.write("Sample\tTSS_Enrichment\tTSS_Signal\tBackground_Signal\n")
        
        all_tss = []
        all_flank = []
        
        for sample_idx in range(n_samples):
            start_col = sample_idx * args.bins_per_sample
            end_col = (sample_idx + 1) * args.bins_per_sample
            sample_data = data[:, start_col:end_col]
            
            enrichment, tss_signal, flank_signal = calculate_enrichment(sample_data)
            
            sample_name = f"{args.celltype}_sample{sample_idx + 1}"
            out.write(f"{sample_name}\t{enrichment:.3f}\t{tss_signal:.3f}\t{flank_signal:.3f}\n")
            print(f"{sample_name}: TSS Enrichment = {enrichment:.3f}")
            
            all_tss.append(tss_signal)
            all_flank.append(flank_signal)
        
        # Overall average
        avg_enrichment = np.mean(all_tss) / np.mean(all_flank) if np.mean(all_flank) > 0 else 0
        out.write(f"{args.celltype}_average\t{avg_enrichment:.3f}\t{np.mean(all_tss):.3f}\t{np.mean(all_flank):.3f}\n")
        print(f"{args.celltype} Average: TSS Enrichment = {avg_enrichment:.3f}")

if __name__ == '__main__':
    main()