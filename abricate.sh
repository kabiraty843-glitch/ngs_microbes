#!/bin/bash

# Define the output directories for your abricate results
OUTPUT_DIR="AMRs"
mkdir -p "$OUTPUT_DIR"
mkdir -p toxin_results

# Loop through all directories starting with "SRR"
for sample_dir in SRR*/; do

    # Get the base name of the directory (e.g., 'SRR27013147...')
    sample_name=$(basename "$sample_dir")

    echo "Processing sample: $sample_name"

    # Define the path to the contigs.fasta file inside the directory
    # The -n option checks if the file exists and is not empty
    if [ -n "$(find "$sample_dir" -name 'contigs.fasta')" ]; then
        contig_path=$(find "$sample_dir" -name 'contigs.fasta')
        
        # Run abricate on the contigs file, redirecting output to the results directory
        abricate "$contig_path" > "$OUTPUT_DIR/${sample_name}_abricate.tsv"

        echo "Analysis for $sample_name complete."
    else
        echo "ERROR: 'contigs.fasta' not found in $sample_dir. Skipping."
    fi
    # Run ABRicate for toxin/virulence genes (VFDB database)
        echo "  Detecting toxin genes..."
        abricate --db vfdb \
            --quiet \
            "$contig_path" > "$OUTPUT_DIR/toxin/${sample_name}_toxin.tsv"
done

echo "All samples analyzed. Results are in the '$OUTPUT_DIR' directory."
