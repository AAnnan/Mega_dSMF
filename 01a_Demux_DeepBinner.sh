#! /bin/bash
  
## Resource Allocation
#SBATCH --time=4-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --array=1-2
#SBATCH --mem=96G
#SBATCH –-cpus-per-task=8

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Deep Binner Demux"


## #SBATCH --array=1-2 parameter should NOT BE CHANGED (depends on the number of GPUs)

## Script to demultiplex (demux) the different barcodes used during sequencing with DeepBinner
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh

source ${CONDA_ACTIVATE} ${condaEnv}
i=$SLURM_ARRAY_TASK_ID

cd /scratch/TMP_Megalodon_${expName}

### Run DeepBinner on the 2 folders simultaneously
deepbinner realtime --stop --native --in_dir ./rawFast5/${i} --out_dir ./demuxed_fast5s_${i}

### Merge the 2 output folders into 1
mkdir -p ./demultiplexed_fast5s_${expName}
rsync -a ./demuxed_fast5s_${i}/ ./demultiplexed_fast5s_${expName}/
rm -r ./demuxed_fast5s_${i}/

conda deactivate