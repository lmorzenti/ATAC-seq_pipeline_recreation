#!/usr/bin/env python3
import csv
import sys

def main():
    cell_type = sys.argv[1]
    sample_ids = sys.argv[2].split(',')
    conditions = sys.argv[3].split(',')
    replicates = sys.argv[4].split(',')
    bams = sys.argv[5].split(',')
    peaks = sys.argv[6].split(',')
    
    output_file = f"{cell_type}_diffbind_samplesheet.csv"
    
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['SampleID', 'Tissue', 'Factor', 'Condition', 
                        'Replicate', 'bamReads', 'Peaks', 'PeakCaller'])
        
        for i in range(len(sample_ids)):
            writer.writerow([
                sample_ids[i],
                'cells',
                'ATAC',
                conditions[i],
                replicates[i],
                bams[i],
                peaks[i],
                'narrow'
            ])

if __name__ == '__main__':
    main()