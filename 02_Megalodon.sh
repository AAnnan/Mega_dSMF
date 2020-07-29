#! /bin/bash

## Allocate resources
#SBATCH --time=8-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=256G
#SBATCH –-cpus-per-task=48

## job metadata
#SBATCH --job-name="Megalodon"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

## Script to run Megalodon iteratively on all listed barcodes
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of bin directory inside Guppy directory and export it as ${GUPPY_DIR}
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ~/.bashrc
source ${CONDA_ACTIVATE} ${condaEnv}

cd /scratch/TMP_Megalodon_${expName}

##Get Rerio's research model from GitHub (if it doesn't exist already)
if [[ ! -f ./rerio/basecall_models/res_dna_r941_min_modbases-all-context_v001.cfg ]]
then
	echo "Installing Rerio's modbases all context research model"
    git clone https://github.com/nanoporetech/rerio
	python rerio/download_model.py rerio/basecall_models/res_dna_r941_min_modbases-all-context_v001
fi

# Command to output: basecalls mod_basecalls mappings mods per_read_mods mod_mappings
# Compute settings: GPU device 0 and 48 CPU cores
# Other useful options : --num-reads 50000 \ --mod-motif Z GC 1 \

for barcode in ${barcodesOfInterest[@]} ; do
        megalodon ./demultiplexed_fast5s/${barcode}/ --guppy-server-path ${GUPPY_DIR}/guppy_basecall_server \
                --guppy-params "-d ./rerio/basecall_models/" \
                --guppy-config res_dna_r941_min_modbases-all-context_v001.cfg \
                --outputs basecalls mod_basecalls mappings mods per_read_mods mod_mappings \
                --output-directory ./megalodon_results_${barcode}/ \
                --reference $genomeFile \
                --mod-motif Z GCG 1 --mod-motif Z HCG 1 --mod-motif Z GCH 1 \
                --write-mods-text \
                --mod-output-formats bedmethyl wiggle \
                --mod-map-base-conv C T --mod-map-base-conv Z C \
                --devices 0 --processes 48
done

# Copy Megalodon's results to the work dir
cp -r ./megalodon_results_* ${work_DIR}

conda deactivate