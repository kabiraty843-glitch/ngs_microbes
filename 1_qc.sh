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

