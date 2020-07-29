#! /bin/bash

# Get Working Directory (1 above current)
work_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd ../ && pwd )"

# name of your conda environment
condaEnv=MethylBC

# name of experiment
expName="20190830_dsmf"  

# barcodes used (Space separated)
barcodesOfInterest=(barcode01 barcode02 barcode03 barcode04)

# Absolute path of dir containing the raw fast5 from sequencing
rawFast5_DIR=/home/aannan/myimaging/20190830-dsmf-trainData/fast5Files

# location of genome file for alignment
genomeFile=/mnt/imaging.data/pmeister/ce11/genome.fa


#### Modifications you're looking for #####
# Default is 3 motifs:  --mod-motif Z GCG 1 --mod-motif Z HCG 1 --mod-motif Z GCH 1

# Motifs can't be overlapping
# Pos1: Y=6mA (alt to A); Z=5mC (alt to C)
# Pos2: motif to search (H is any base except G)
# Pos3: relative position of modified base within that motif
# Add --mod-motif Pos1 Pos2 Pos3 to the megalodon line in 02_Megalodon.sh once you've decided.
