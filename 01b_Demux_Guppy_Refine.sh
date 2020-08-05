#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --array=0-3
#SBATCH --mem=240G
#SBATCH –-cpus-per-task=30

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Guppy Refine Demux"


## #SBATCH --array=0-3 parameter should be CHANGED according to NUMBER OF BARCODES:
## array=0-(total number of barcodes-1)

## Script to refine DeepBinner's demultiplexing output with Guppy Barcoder
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ~/.bashrc

source ${CONDA_ACTIVATE} ${condaEnv}
i=$SLURM_ARRAY_TASK_ID

cd /scratch/TMP_Megalodon_${expName}

### Get Rerio's research model from GitHub (if it doesn't exist already)
if [[ ! -f ./rerio/basecall_models/res_dna_r941_min_modbases-all-context_v001.cfg ]]
then
	echo "Installing Rerio's modbases all context research model"
    git clone https://github.com/nanoporetech/rerio
	python rerio/download_model.py rerio/basecall_models/res_dna_r941_min_modbases-all-context_v001
fi
# Copy Guppy's barcoding models into Rerio's folder
cp ${GUPPY_DIR}/../data/barcoding/* ./rerio/basecall_models/barcoding/

### Run Guppy Basecaller (to refine demultiplexing)

${GUPPY_DIR}/guppy_basecaller --input_path ./demultiplexed_fast5s_${expName}/${barcode[i]} \
	--save_path ./guppyBC/${barcode[i]} \
	--data_path ./rerio/basecall_models/ \
    --config res_dna_r941_min_modbases-all-context_v001.cfg \
	--records_per_fastq 40000 --recursive \
	--barcode_kits "EXP-NBD104" \
	--fast5_out \
	--device auto

#Move fast5s from children folders to the parent
find ./guppyBC/${barcode[i]}/workspace/ -type f -name "*.fast5" | xargs mv -t ./guppyBC/${barcode[i]}/workspace/
#Create a txt file containing the absolute filename of all barcoded fast5s
awk -v barcode="${barcode[i]}" '$21==barcode {print "./guppyBC/"barcode"/workspace/"$2".fast5"}' ./guppyBC/${barcode[i]}/sequencing_summary.txt > list_ids_${barcode[i]}.txt
#Move the fast5s contained in the list to their final directory
mkdir -p ./final_fast5s_${expName}/${barcode[i]}
xargs mv -t ./final_fast5s_${expName}/${barcode[i]} < list_ids_${barcode[i]}.txt

### Perform single to multi fast5 conversion (for storage, as to not have millions of small files)

single_to_multi_fast5 -i ./final_fast5s_${expName}/${barcode[i]}/ \
    -s ${work_DIR}/final_multifast5s_${expName}/${barcode[i]}/ \
    --threads 30 \
    --filename_base ${expName}_${barcode[i]} \
    --batch_size 20000 

conda deactivate