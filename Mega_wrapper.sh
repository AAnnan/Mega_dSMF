#!/bin/bash

######################
# read settings-file #
######################
source ./varSettings.sh

###################################################
### Processing steps of the Mega_dSMF pipeline  ###
###################################################
steps=( 01a_Demux_DeepBinner.sh 01b_Demux_Guppy.sh 02_Megalodon.sh 03_BigWig_metPlot.sh )

#################
# echo settings #
#################
echo "Mega_dSMF pipeline started..."
echo -e "Experiment Name:" '\t' $expName
echo -e "Barcodes:" '\t' $barcodesOfInterest
echo -e "Model used:" '\t' $modelConfig
echo -e "Perform 2-pass demultiplexing:" '\t' $two_pass
echo -e "Perform pycoQC quality control:" '\t' $qc
echo -e "Megalodon Outputs:" '\t' $outputs

#############
# Mega_dSMF #
#############

### DEMULTIPLEXING
if [ "${two_pass}" = "yes" ]; then
	echo "2-pass demultiplexing: (1) Barcoding with DeepBinner..."
	step1=$(sbatch 01a_Demux_DeepBinner.sh)
	step1="${step1//[^0-9]/}"
	echo "2-pass demultiplexing: (2) Barcoding with Guppy Barcoder..."
	step2=$(sbatch --dependency=afterany:$step1 01b_Demux_Guppy.sh)
	step2="${step2//[^0-9]/}"
elif [ "${two_pass}" = "no" ]; then
	echo "1-pass demultiplexing: Barcoding with Guppy Barcoder..."
	step2=$(sbatch 01b_Demux_Guppy.sh)
	step2="${step2//[^0-9]/}"
else
	echo "Invalid two_pass variable in varSettings.sh. Must be yes or no."
    exit
fi

### MEGALODON
echo "Megalodon augmented BaseCalling..."
step3=$(sbatch --dependency=afterany:$step2 02_Megalodon.sh)
step3="${step3//[^0-9]/}"

### ANALYSIS
echo "Building dSMF BigWig and Methylation plot..."
step4=$(sbatch --dependency=afterany:$step3 03_BigWig_metPlot.sh)
