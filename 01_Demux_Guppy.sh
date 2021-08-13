#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=256G
#SBATCH –-cpus-per-task=32

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Guppy Demux"

## Script to perform demultiplexing with Guppy Barcoder
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ${CONDA_ACTIVATE} ${condaEnv}

cd /scratch/TMP_Megalodon_${expName}

# Retrieve the path of the first fast5 it finds
f5_path=$(find ${rawFast5_DIR} -type f -name "*.fast5" | head -1)
# Check with ont-fast5-api if it's multi (True) or single (False)
is_multi=$(python -c "import sys;from ont_fast5_api.fast5_interface import is_multi_read;print(is_multi_read(sys.argv[1]))" ${f5_path} 2>&1)

# If reads are single, perform single to multi
if [ "$is_multi" = False ]; then 
	single_to_multi_fast5 \
		--input_path ${rawFast5_DIR} \
		--save_path /scratch/TMP_Megalodon_${expName}/raw_multifast5s_${expName} \
		--threads 32 \
		--filename_base ${expName} \
		--batch_size 6000

	rawFast5_DIR=/scratch/TMP_Megalodon_${expName}/raw_multifast5s_${expName}
fi

# Run the Guppy basecaller to extract barcoding information from the raw reads
# This information is stored in "sequencing_summary.txt"
${GUPPY_DIR}/guppy_basecaller \
	--input_path ${rawFast5_DIR} \
	--save_path ./guppyBC \
	--data_path ./rerio/basecall_models/ \
    --config ${modelConfig}.cfg \
	--records_per_fastq 20000 \
	--recursive \
	--barcode_kits ${bc_kit} \
	--progress_stats_frequency 10 \
	--device cuda:0

# Keep only the sequencing_summary, discard the rest of the output
mv ./guppyBC/sequencing_summary.txt ./sequencing_summary_${expName}.txt
rm -r ./guppyBC

# Demux the original fast5s (non-basecalled) into different barcode folders
# Based on the guppy basecall output in sequencing_summary
demux_fast5 \
--input ${rawFast5_DIR} \
--save_path ${work_DIR}/output/final_multifast5s_${expName}/ \
--summary_file sequencing_summary_${expName}.txt \
--filename_base "${expName}_rawF5_" \
--batch_size 6000 \
--threads 32 \
--recursive

# Move the barcoded reads of interest to a new folder for Megalodon
mkdir -p ${work_DIR}/output/final_multifast5s_${expName}/barcodesToMegalodon
for bc in ${barcodesOfInterest[@]}; do
	mv ${work_DIR}/output/final_multifast5s_${expName}/${bc} ${work_DIR}/output/final_multifast5s_${expName}/barcodesToMegalodon
done

echo "barcodesToMegalodon_DIR="${work_DIR}/output/final_multifast5s_${expName}/barcodesToMegalodon >> ${work_DIR}/varSettings.sh

conda deactivate