# 





**REPORT ON SOUTH AFRICAN POLONY AMR AND TOXIN IDENTIFICATION:
**
This report provides an analysis of the 2017-2018 listeriosis outbreak in south Africa, which was one of the largest on record. Using whole-genome sequencing, it was confirmed that the outbreak was caused by _Listeria monocytogenes_.The analysis also confirmed the bacterium's antimicrobial resistance profile and its key virulence factors. These findings were crucial in the creation of evidence based treatment recommendations to help in the guidance of recommendation of public health response.

#





**PROCESS:**

Making a new directory and downloading the neccessary dataset
```
#making a new directory for easy access
mkdir ngs_microbes
#making a new directory where raw files will be and changing it to the working directory
mkdir raw_files && cd raw_files
#downloading the bash script that contains all 100 genomes
wget  https://raw.githubusercontent.com/HackBio-Internship/2025_project_collection/refs/heads/main/SA_Polony_100_download.sh
````
Viewing the contents of the bash script
```
nano SA_Polony_100_download.sh
```
Downloading the paired end reads
```
bash SA_Polony_100_download.sh
```
#making a new scipt to carry out fastqc on all the genomes
```
nano qc.sh
````
contents of the qc.sh script
```
#!/bin/bash
mkdir qc     #making a new directory where the outputs will be
for sample in *.fastq.gz;  #for any content that has fastq.qz attached to it
do
       fastqc -o qc "$sample"   #run fastqc on it and put the output in qc
done
#create a multiqc report to aid easy viewing
multiqc "qc" \
--output "qc" \
--filename "multiqc_report.html"
--quiet
echo "raw data quality has been assessed and multiqc report has been successfully created"
```
run qc.sh script
```
bash qc.sh
```
create a bash script where trimming of paired end reads by fastp will take place
```
nano trim.sh
```
contents of the bash script
```
#!/bin/bash
raw_data= ../ngs_microbes/raw_data

mkdir -p trimmed  #make a new directory named trimmed
#check if the raw data exists
if [ -z "$(ls -A $raw_data/*.fastq.gz 2>/dev/null)" ]; then
echo "error, fastq not found"
exit
fi
  for r1 in *_1.fastq.gz;     #this starts a loop with r taking the value of each file in raw_files that end in _1.fastq.gz
do
        r2="${r1/_1.fastq.gz/_2.fastq.gz}"      #this finds the matching ‘2’ file by replacing _1.fastq.gz with  _2.fastq.gz
        sample=$(basename "$r1" _1.fastq.gz) #extracts just the sample name
        fastp \
          -i "$r1" \      #input 1
          -I "$r2" \       #input 2
          -o "trimmed/${sample}_1.trimmed.fastq.gz" \    #trimmed output 1
          -O "trimmed/${sample}_2.trimmed.fastq.gz"
          --html "$(fastp_report/$(basename)_fastp.html" \
          --json "$(fastp_report/$(basename)_fastp.json" \
          
          #trimmed output 2

done
```
Execute the bash script
```
bash trim.sh
```
Write a new bash script to perform De-novo assembly with spades.py
```
nano assembly.sh
```
Contents of the bash script
```
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
```
create a new script to perform quast and check if the assembly with spades.py was properly carried out
```
nano quast.sh
```
contents of the bash script
```
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
```
Create a new script to identify the organism using blast 
```
nano blast.sh
```
Contents of the bash script
```
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
if grep -q -i "Listeria monocytogenes" "$Blast/blast_identification_results.tsv"; then
    echo "Listeria monocytogenes successfully identified via BLAST"
else
    echo "Expected organism not found"
fi
```

Create a new script to extract the AMR genes and the toxins present in the samples using abricate
```
nano abricate.sh
```
Contents of the script
```
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
```
#
**RESULTS**

The bacteria strain causing the outbreak was identified as _Listeria monocytogenes_. It was found to contain the following Anti microbial Resistance (AMR) genes:

**Fosfomycin resistance thiol transferase (FosX):**
This gene conferring resistance to the antibiotic fosfomycin, was detected with 100 percent identity and coverage

**Lincomycin resistant ABC-F type ribosomal protection protein:** 
This gene providing resistance to lincomycin and other macrolide-lincosamide-streptogramin B (MLS$_{B}$) antibiotics, was also identified with 100 percent identity and coverage.

**Multiple peptide resistance factor (MprF):**
it contributes to resistance against certain antibiotics like daptomycin by modifying the bacteria cell membrane to repek the drug. This same mechanism helps the bacteria evade the host's immune system's antimicrobial peptides, making it both a virulence and an AMR gene.

**norB:**
It confers resistance to a broad range of antibiotics by acting as an efflux pump. It pumps out various drugs including macrolides, flouroquinolones and some beta-lactams thus making them ineffective.

**It was also found to contain the following toxins**

actA, bsh ,clpC ,clpE ,fbpA ,gtcA ,hly ,hpt ,iap/cwhA ,icl, inlA, inlB, inlC, inlF, inlK,lap, lapB, llsA,llsB, llsD, llsG,, llsH, llsP, llsX, llsY, lntA, lpeA, lplA1, lspA, oatA, pdgA, plcA, plcB,prfA ,prsA2 ,vip
#
These virulence factors are coordinated in a way to help:
**Evade the Immune System**: Listeriolysin O (hly), a pore-forming toxin, is the key protein that allows the bacteria to escape the host cell's vacuole. This escape is critical for its survival.
**Invade Host Cells**: The Internalin proteins (inlA, inlB, etc.) are essential for host cell invasion. They help Listeria attach to and enter cells that are not typically phagocytic.
**Spread Systemically**: The ActA protein hijacks the host's machinery to propel the bacteria directly from one cell to another. This cell-to-cell spread makes it difficult for the host's immune system to clear the infection.
#
**Antibiotic Recommendations**

Based on the AMR profile, the recommended first-line therapy for a Listeria monocytogenes infection is a** beta-lactam antibiotic**, such as** ampicillin or penicillin G**. These are the standard of care for listeriosis and are not affected by the identified resistance genes. For severe infections like meningitis, combining ampicillin with an aminoglycoside like gentamicin is recommended for a synergistic effect.
#
**What to Avoid**

Based on the analysis and known characteristics of _Listeria_, the following antibiotics should be avoided:

**Fosfomycin**: The presence of the FosX gene directly confers resistance to this drug.
**Lincomycin**: The ABC-F ribosomal protection protein gene provides resistance to lincomycin and related antibiotics.
**Cephalosporins**: _Listeria monocytogenes_ is inherently resistant to all cephalosporins (e.g., ceftriaxone), so they are ineffective against this pathogen.
#
**Public Health Implications**
The identified genes highlight the pathogen's ability to cause severe, difficult-to-treat infections. The toxins and virulence factors (Listeriolysin O, Internalins, and ActA) enable the bacteria to evade the immune system and cause invasive diseases such as meningitis and septicemia. The AMR genes (FosX and ABC-F) further complicate treatment by limiting the choice of effective antibiotics. This underscores the need for continuous genomic surveillance to guide clinical decisions and manage the spread of antimicrobial resistance. The findings also highlight the importance of strict food safety measures, as Listeria is a foodborne pathogen particularly dangerous to vulnerable populations.
#
**Sources**

The information provided is based on established scientific knowledge in microbiology, infectious disease, and public health. Key sources for these findings include:
Clinical Practice Guidelines: Recommendations from infectious disease societies such as the Infectious Diseases Society of America (IDSA).
Bioinformatics Databases: The CARD (Comprehensive Antibiotic Resistance Database) and VFDB (Virulence Factor Database) are primary sources for gene function.
Scientific Literature: Peer-reviewed studies on the mechanisms of virulence and antimicrobial resistance in Listeria monocytogenes and other bacteria.












