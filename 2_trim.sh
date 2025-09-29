#!/bin/bash
raw_data= ../ngs_microbes/raw_data

mkdir -p trimmed  #make a new directory named trimmed
mkdir fastp_report
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
          --html "${fastp_report}/${basename}_fastp.html" \
          --json "${fastp_report}/${basename}_fastp.json" 
          
          #trimmed output 2

done
