#! /bin/bash

# Get current Directory 
work_DIR=$(pwd)

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

###############
## MEGALODON ##
###############

# Outputs chosen (Space separated)
# Possible output: basecalls mod_basecalls mappings mods per_read_mods mod_mappings
# Refer to Megalodon_Output_Notes.txt if you're unsure
# Default: mods per_read_mods mod_mappings
outputs=(mods per_read_mods mod_mappings)

#### Modifications you're looking for #####
# Default is 3 motifs:  --mod-motif Z GCG 1 --mod-motif Z HCG 1 --mod-motif Z GCH 1

# Motifs can't be overlapping
# Pos1: Y=6mA (alt to A); Z=5mC (alt to C)
# Pos2: motif to search (H is any base except G)
# Pos3: relative position of modified base within that motif
# Add --mod-motif Pos1 Pos2 Pos3 to the megalodon line in 02_Megalodon.sh once you've decided.

