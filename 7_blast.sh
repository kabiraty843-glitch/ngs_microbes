#!/bin/bash

#Run BLAST on a single representative sample to identify organism present.

Assembly="../results/assembly"
Blast="../results/blast"
mkdir -p "$Blast"

echo "Running BLAST to identify organism present"

# Get the first successful assembly
assembly_rep=$(find "$Assembly" -name "contigs.fasta" | head -1)

if [[ -z "$assembly_rep" ]]; then
    echo "Error: assembly not found. Run assembly script first."
    exit 1
fi

Sample=$(basename $(dirname "$assembly_rep"))
echo "Using representative sample: $Sample"

# Extract the first contig for quick BLAST
head -n 200 "$assembly_rep" > "$Blast/representative_contig.fasta"

blastn \
    -query "$Blast/representative_contig.fasta" \
    -db nt \
    -remote \
    -outfmt "6 std stitle" \
    -max_target_seqs 5 \
    -evalue 1e-50 \
    -out "$Blast/blast_identification_results.tsv"


awk -F'\t' '{printf "%-60s %-6s %-6s %-10s\n", $13, $3, $4, $11}' "$Blast/blast_identification_results.tsv" | head -5


# Confirm the identity of Listeria monocytogenes in the results
if grep -q -i "listeria monocytogenes" "$Blast/blast_identification_results.tsv"; then
    echo "Listeria monocytogenes successfully identified via BLAST"
else
    echo "Expected organism not found"
fi
