#! /bin/bash

## Allocate resources
#SBATCH --time=8-00:00:00
#SBATCH --partition=gpu
#SBATCH --array=0-1
#SBATCH --mem=32G
#SBATCH –-cpus-per-task=8

## job metadata
#SBATCH --job-name="03"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

## #SBATCH --array parameter should be CHANGED according to NUMBER OF BARCODES:
## array=0-(total number of barcodes-1)

## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}


source ./varSettings.sh

source ${CONDA_ACTIVATE} ${condaEnv}

i=$SLURM_ARRAY_TASK_ID
cd /scratch/TMP_Megalodon_${expName}/megalodon_results_${barcodesOfInterest[i]}

#Get 1-fraction methylation
awk '{if ($2 ~/^[0-1]\.?[0-9]*$/) print $1,1-$2; else print $0}' modified_bases.5mC.fwd_strand.wig > ${expName}_${barcodesOfInterest[i]}_fwd.wig
awk '{if ($2 ~/^[0-1]\.?[0-9]*$/) print $1,1-$2; else print $0}' modified_bases.5mC.rev_strand.wig > ${expName}_${barcodesOfInterest[i]}_rev.wig

#Convert wig to Bigwig
wigToBigWig ${expName}_${barcodesOfInterest[i]}_fwd.wig ${SOFTWARE_DIR}/ce11.chrom.sizes ${expName}_${barcodesOfInterest[i]}_fwd.bw
wigToBigWig ${expName}_${barcodesOfInterest[i]}_rev.wig ${SOFTWARE_DIR}/ce11.chrom.sizes ${expName}_${barcodesOfInterest[i]}_rev.bw

# Create barplot of the proportion of methylated motif sites
python ${work_DIR}/methyl_plot.py ${barcodesOfInterest[i]}

# Copy Megalodon's results to the work dir
cp -r ../megalodon_results_${barcodesOfInterest[i]}/ ${work_DIR}

# Remove previously created intermediate folders and files
rm -rf ./rawFast5 ./guppyBC ./demultiplexed_fast5s_${expName} list_ids_*.txt rawFast5s*.txt

conda deactivate