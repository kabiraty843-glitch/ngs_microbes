#!/bin/bash

# Create the output directory
mkdir -p assembly

# Check if trimmed data is available
if [ -z "$(ls -A $trimmed_data/*.fastq.gz 2>/dev/null)" ]; then
    echo "Error: trimmed fastq files not found"
    exit 1
fi
    echo "starting assembly process now"


# Loop through all trimmed R1 fastq files
for r1_file in trimmed/*_1.trimmed.fastq.gz; do

    # Get the corresponding R2 file by replacing '_1' with '_2'
    r2_file=${r1_file/_1.trimmed.fastq.gz/_2.trimmed.fastq.gz}

    # Extract the sample name from the R1 filename
    sample_name=$(basename "${r1_file}" "_1.trimmed.fastq.gz")

    # Check if the corresponding R2 file exists
    if [[ -f "$r2_file" ]]; then
        echo "Starting assembly #$((count + 1)) for sample: ${sample_name}"
        spades.py –phred-offset  -1 "$r1_file" -2 "$r2_file" -o "assembly/${sample_name}"
        
        echo "Warning: R2 file not found for ${r1_file}. Skipping."
    fi
done
