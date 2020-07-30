#! /bin/bash

## Allocate resources
#SBATCH --time=40:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=170G
#SBATCH –-cpus-per-task=32

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Demux"

## Script to demultiplex (demux) the different barcodes used during sequencing
## .bashrc should include location of conda activate script and export it s ${CONDA_ACTIVATE}

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

### Perform single to multi fast5 conversion (for storage)
for barcode in ${barcodesOfInterest[@]} ; do
        single_to_multi_fast5 -i ./demultiplexed_fast5s_${expName}/${barcode}/ \
                -s ./demultiplexed_multifast5s_${expName}/${barcode}/ \
                --threads 32 \
                --filename_base ${expName}_${barcode} \
                --batch_size 20000 
done

# Copy the demultiplexed fast5s to the work dir
cp -r ./demultiplexed_multifast5s_${expName} ${work_DIR}

conda deactivate