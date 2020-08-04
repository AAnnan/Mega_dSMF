#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=256G
#SBATCH –-cpus-per-task=16

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Deep Binner Demux"

## Script to demultiplex (demux) the different barcodes used during sequencing with DeepBinner
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ~/.bashrc

source ${CONDA_ACTIVATE} ${condaEnv}

# Create and move to a temporary scratch folder
mkdir -p /scratch/TMP_Megalodon_${expName}/rawFast5
cd /scratch/TMP_Megalodon_${expName}

# Copy the raw fast5s there
cp -r ${rawFast5_DIR} ./rawFast5

### Run DeepBinner
deepbinner realtime --stop --native --in_dir ./rawFast5 --out_dir ./demultiplexed_fast5s_${expName}

# Remove raws
rm -rf ./rawFast5

conda deactivate