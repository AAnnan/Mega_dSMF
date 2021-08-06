#! /bin/bash

####################################
## /!\ TO UPDATE EVERY LAUNCH /!\ ##
####################################

# Short name of the experiment
expName=tester

# barcodes of interest (Space separated)
barcodesOfInterest=(barcode01 barcode04)

# Absolute path of directory containing the raw fast5 from sequencing
rawFast5_DIR=/home/aannan/rawF5_test

# Perform 2-pass demultiplexing (1st pass: DeepBinner, 2nd pass: Guppy Barcoder)
# Only use yes if you've used these barcoding kits: EXP-NBD103, EXP-NBD104 or very similar.
two_pass=no #yes or no


###############################
## MAY OR MAY NOT BE UPDATED ##
###############################

# name of the conda environment that will be created
condaEnv=Mega_dSMF

#barcode kit used
bc_kit=EXP-NBD104

# location of genome file for alignment
genomeFile=/mnt/imaging.data/pmeister/ce11/genome.fa

# Name of Rerio's config model to use
modelConfig=res_dna_r941_min_modbases_5mC_v001

#Probability threshold above which the base of interest will be declared methylated, 
#					   under which the base of interest will be declared canonical
k=0.7

# Perform pycoQC quality control
# Will output html files with QC information (1 per barcode)
qc=no #yes or no

###############
## MEGALODON ##
###############

# Outputs chosen (Space separated)
# Default all outputs except mod_basecalls : basecalls mappings mods per_read_mods mod_mappings
# Refer to Megalodon_Output_Notes.txt
outputs=(basecalls mappings mods per_read_mods mod_mappings)

#### Modifications you're looking for (--mod-motif)#####
# Default is 3 motifs:  --mod-motif Z GCG 1 --mod-motif Z HCG 1 --mod-motif Z GCH 1

# Motifs can't be overlapping
# Pos1: Y=6mA (alt to A); Z=5mC (alt to C)
# Pos2: motif to search (H is any base except G)
# Pos3: relative position of modified base within that motif
# Add --mod-motif Pos1 Pos2 Pos3 to the megalodon line in 02_Megalodon.sh once you've decided.

