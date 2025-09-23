# 





REPORT ON SOUTH AFRICAN POLONY AMR AND TOXIN IDENTIFICATION:

This report provides an analysis of the 2017-2018 listeriosis outbreak in south Africa, which was one of the largest on record. Using whole-genome sequencing, it was confirmed that the outbreak was caused by Listeria monocytogenes.The analysis also confirmed the bacteriums's antimicrobial resistance profile and its key virulence factors. These findings were crucial in the creation of evidence based treatment recommendations to help in the guidance of recommendation of public health response.

#





PROCESS:

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








