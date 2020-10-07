#!/bin/bash

#  There are several options for the '--dependency' flag that depend on the status of Job1. e.g.
# --dependency=afterany:Job1	Job2 will start after Job1 completes with any exit status
# --dependency=after:Job1	Job2 will start any time after Job1 starts
# --dependency=afterok:Job1	Job2 will run only if Job1 completed with an exit status of 0

######################
# read settings-file #
######################
source ./varSettings.sh

###################################################
### Processing steps of the Mega_dSMF pipeline  ###
###################################################
if [ "${two_pass}" = "yes" ]; then
	steps=( 01a_Demux_DeepBinner.sh 01b_Demux_Guppy.sh 02_Megalodon.sh 03_BigWig_metPlot.sh )
elif [ "${two_pass}" = "no" ]; then
	steps=( 01b_Demux_Guppy.sh 02_Megalodon.sh 03_BigWig_metPlot.sh )
else
	echo "Invalid two_pass variable in varSettings.sh. Must be yes or no."
    exit
fi

#################
# echo settings #
#################
echo "Mega_dSMF pipeline started..."
echo -e "Experiment Name:" '\t' $expName
echo -e "Barcoding Kit:" '\t' $bc_kit
echo -e "Barcodes:" '\t' $barcodesOfInterest
echo -e "Perform 2-pass barcoding:" '\t' $two_pass
echo -e "Perform pycoQC barcode QC:" '\t' $qc
echo -e "Megalodon Outputs:" '\t' $outputs 
echo -e "Model chosen:" '\t' $modelConfig
echo -e "Methylation threshold chosen:" '\t' K=$k '\n'

#################
# echo steps #
#################
echo "These scripts will be run in order:"
echo ${steps[@]}
echo "script2 will run only if script1 completed with an exit status of 0 (OK)"
echo "Check the run regularly. The pipeline speed is about 20h/1M reads"

#############
# Mega_dSMF #
#############

### DEMULTIPLEXING
if [ "${two_pass}" = "yes" ]; then

	step1=$(sbatch 01a_Demux_DeepBinner.sh)
	step1="${step1//[^0-9]/}"

	step2=$(sbatch --dependency=afterok:$step1 01b_Demux_Guppy.sh)
	step2="${step2//[^0-9]/}"
elif [ "${two_pass}" = "no" ]; then

	step2=$(sbatch 01b_Demux_Guppy.sh)
	step2="${step2//[^0-9]/}"
fi

### MEGALODON
step3=$(sbatch --dependency=afterok:$step2 02_Megalodon.sh)
step3="${step3//[^0-9]/}"

### ANALYSIS
step4=$(sbatch --dependency=afterok:$step3 03_BigWig_metPlot.sh)
