#! /bin/bash

# name of your conda environment
condaEnv=Mega_dSMF

# Short name of experiment
expName="tester"  

# barcodes used (Space separated)
barcodesOfInterest=(barcode01 barcode04)

# Absolute path of dir containing the raw fast5 from sequencing
rawFast5_DIR=/home/aannan/rawF5_test

# location of genome file for alignment
genomeFile=/mnt/imaging.data/pmeister/ce11/genome.fa

#Probability threshold above which a C will be declared methylated
k=0.85

###############
## MEGALODON ##
###############

# Outputs chosen (Space separated)
# Default all outputs except mod_basecalls (bottleneck issue with HDF files, is likely to change): basecalls mappings mods per_read_mods mod_mappings
# Refer to Megalodon_Output_Notes.txt if you're unsure
outputs=(basecalls mappings mods per_read_mods mod_mappings)

#### Modifications you're looking for (--mod-motif)#####
# Default is 3 motifs:  --mod-motif Z GCG 1 --mod-motif Z HCG 1 --mod-motif Z GCH 1

# Motifs can't be overlapping
# Pos1: Y=6mA (alt to A); Z=5mC (alt to C)
# Pos2: motif to search (H is any base except G)
# Pos3: relative position of modified base within that motif
# Add --mod-motif Pos1 Pos2 Pos3 to the megalodon line in 02_Megalodon.sh once you've decided.

