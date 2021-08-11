#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=96G
#SBATCH –-cpus-per-task=6

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Guppy Demux"

## Script to perform demultiplexing with Guppy Barcoder
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ${CONDA_ACTIVATE} ${condaEnv}

cd /scratch/TMP_Megalodon_${expName}

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

# Keep only the sequencing_summary discard the rest of the output
mv ./guppyBC/sequencing_summary.txt ./sequencing_summary_${expName}.txt
rm -r ./guppyBC

for bc in ${barcodesOfInterest[@]}; do
	# Create a txt file containing read_ids of all barcoded fast5s
	awk -v barcode="${bc}" '$21==barcode {print $2}' ./sequencing_summary_${expName}.txt > list_ids_${bc}.txt
	
	# Subset the original fast5s (non-basecalled) into different barcode folders
	fast5_subset \
	--input ${rawFast5_DIR} \
	--save_path ${work_DIR}/output/final_multifast5s_${expName}/${bc} \
    --read_id_list list_ids_${bc}.txt \
    --filename_base "${expName}_${bc}_" \
    --batch_size 4000 \
    --recursive
done

conda deactivate