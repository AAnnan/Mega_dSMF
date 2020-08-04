#! /bin/bash

## Resource Allocation
#SBATCH --time=10-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --array=0-3
#SBATCH --mem=240G
#SBATCH –-cpus-per-task=30

## job metadata
#SBATCH --job-name="Megalodon"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail


## #SBATCH --array=0-3 parameter should be CHANGED according to NUMBER OF BARCODES:
## array=0-(total number of barcodes-1)

## Script to run Megalodon on all listed barcodes on maximum GPUs available
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of bin directory inside Guppy directory and export it as ${GUPPY_DIR}
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ~/.bashrc
source ${CONDA_ACTIVATE} ${condaEnv}

# Move to scratch temp experiment folder
cd /scratch/TMP_Megalodon_${expName}

# Remove previously created intermediate folders and files
rm -rf ./rawFast5 ./guppyBC ./demultiplexed_fast5s list_ids_*

# Compute settings: 1 GPU and 30 CPU cores
# Other useful options : --num-reads 50000 \ --mod-motif Z GC 1 \

megalodon ./final_fast5s_${expName}/${barcode[i]}/ --guppy-server-path ${GUPPY_DIR}/guppy_basecall_server \
        --guppy-params "-d ./rerio/basecall_models/" \
        --guppy-config res_dna_r941_min_modbases-all-context_v001.cfg \
        --outputs ${outputs[@]} \
        --output-directory ./megalodon_results_${barcode[i]}/ \
        --reference $genomeFile \
        --mod-motif Z GCG 1 --mod-motif Z HCG 1 --mod-motif Z GCH 1 \
        --write-mods-text \
        --mod-aggregate-method binary_threshold \
        --mod-binary-threshold 0.875 \
        --mod-output-formats bedmethyl wiggle \
        --mod-map-base-conv C T --mod-map-base-conv Z C \
        --devices 0 --processes 30

# Copy Megalodon's results to the work dir
cp -r ./megalodon_results_${barcode[i]}/ ${work_DIR}

conda deactivate