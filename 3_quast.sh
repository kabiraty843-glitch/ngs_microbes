#!/bin/bash

# Set directories
Assembly="../results/assembly"
Quast="../results/quast_reports"

# Create output directory
echo "Creating output directory: $Quast"
mkdir -p "$Quast"

# Check if assemblies are available
if [ -z "$(ls -A $Assembly/*/contigs.fasta 2>/dev/null)" ]; then
    echo "Error: No assembly files found"
    exit 1
fi

echo "assessing genome quality with quast"

# Process each successful assembly
success_count=0
total_count=0

for assembly_dir in "$Assembly"/*; do
    sample_name=$(basename "$assembly")
    contigs_file="$assembly/contigs.fasta"
    
    total_count=$((total_count + 1))
    
    if [ -f "$contigs_file" ] && [ -s "$contigs_file" ]; then
        echo "Running QUAST for sample: $sample_name"
        
        # Run QUAST quality assessment
        quast.py \
            -o "$Quast/$sample_name" \
            "$contigs_file" \
            --threads 2 \
            --silent
        
        success_count=$((success_count + 1))
    else
        echo "error: No contigs file found for $sample_name, skipping QUAST"
    fi
done
