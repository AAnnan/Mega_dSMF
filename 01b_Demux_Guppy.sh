#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --array=0-24
#SBATCH --mem=240G
#SBATCH –-cpus-per-task=30

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Guppy Demux"

## Script to perform demultiplexing with Guppy Barcoder
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh

i=$SLURM_ARRAY_TASK_ID
j=$SLURM_ARRAY_JOB_ID
nb_arr=$SLURM_ARRAY_TASK_MAX
let nb_job="${#barcodesOfInterest[@]}"

if [ "${i}" = 0 ]; then scancel --quiet ${j}_[${nb_job}-${nb_arr}]; else sleep 1;fi 

source ${CONDA_ACTIVATE} ${condaEnv}

cd /scratch/TMP_Megalodon_${expName}

### Run Guppy Basecaller
if [ "${two_pass}" = "yes" ]; then
	${GUPPY_DIR}/guppy_basecaller --input_path ./demultiplexed_fast5s_${expName}/${barcodesOfInterest[${i}]} \
		--save_path ./guppyBC/${barcodesOfInterest[${i}]} \
		--data_path ./rerio/basecall_models/ \
	    --config ${modelConfig}.cfg \
		--records_per_fastq 40000 --recursive \
		--barcode_kits ${bc_kit} \
		--fast5_out \
		--device auto

	#Move fast5s from children folders to the parent
	find ./guppyBC/${barcodesOfInterest[${i}]}/workspace/ -type f -name "*.fast5" | xargs mv -t ./guppyBC/${barcodesOfInterest[${i}]}/workspace/
	#Create a txt file containing the absolute filename of all barcoded fast5s
	awk -v barcode="${barcodesOfInterest[${i}]}" '$21==barcode {print "./guppyBC/"barcode"/workspace/"$1}' ./guppyBC/${barcodesOfInterest[${i}]}/sequencing_summary.txt > list_ids_${barcodesOfInterest[${i}]}.txt
	#Move the fast5s contained in the list to their final directory
	mkdir -p ./final_fast5s_${expName}/${barcodesOfInterest[${i}]}
	xargs mv -t ./final_fast5s_${expName}/${barcodesOfInterest[${i}]} < list_ids_${barcodesOfInterest[${i}]}.txt

	### Perform single to multi fast5 conversion (for storage, as to not have millions of small files)
	single_to_multi_fast5 -i ./final_fast5s_${expName}/${barcodesOfInterest[${i}]}/ \
	    -s ${work_DIR}/output/final_multifast5s_${expName}/${barcodesOfInterest[${i}]}/ \
	    --threads 30 \
	    --filename_base ${expName}_${barcodesOfInterest[${i}]} \
	    --batch_size 20000

elif [ "${two_pass}" = "no" ]; then
	#Only run on 1 instance
	if [ "${i}" = "0" ]; then

		#Check if raw fast5s are single or multi. If multi, transform to singles
		first_f5=$(find ${rawFast5_DIR} -name *.fast5 -print -quit)
		singl_or_multi=$(grep -ac 'read_id' ${first_f5})
		
		if [ "${singl_or_multi}" -gt 1 ]; then
			multi_to_single_fast5 --input_path ${rawFast5_DIR} \
				--save_path ./single_rawFast5 \
				--threads 30 \
				--recursive

			rawFast5_DIR=./single_rawFast5
		fi

		${GUPPY_DIR}/guppy_basecaller --input_path ${rawFast5_DIR} \
			--save_path ./guppyBC \
			--data_path ./rerio/basecall_models/ \
		    --config ${modelConfig}.cfg \
			--records_per_fastq 40000 --recursive \
			--barcode_kits ${bc_kit} \
			--fast5_out \
			--device auto

		#Move fast5s from children folders to the parent
		find ./guppyBC/workspace/ -type f -name "*.fast5" | xargs mv -t ./guppyBC/workspace/
		for bc in ${barcodesOfInterest[@]}; do
			#Create a txt file containing the absolute filename of all barcoded fast5s
			awk -v barcode="${bc}" '$21==barcode {print "./guppyBC/workspace/"$1}' ./guppyBC/sequencing_summary.txt > list_ids_${bc}.txt
			#Move the fast5s contained in the list to their final directory
			mkdir -p ./final_fast5s_${expName}/${bc}
			xargs mv -t ./final_fast5s_${expName}/${bc} < list_ids_${bc}.txt

			### Perform single to multi fast5 conversion (for storage, as to not have millions of small files)
			single_to_multi_fast5 -i ./final_fast5s_${expName}/${bc}/ \
			    -s ${work_DIR}/output/final_multifast5s_${expName}/${bc}/ \
			    --threads 30 \
			    --filename_base ${expName}_${bc} \
			    --batch_size 20000
		done
	fi
fi

### Run pycoQC (or not)
if [ "${two_pass}" = "yes" ] || [ "${i}" = "0" ]; then #if 2-pass or if 1 pass on specific array job
	if [ "${qc}" = "yes" ]; then

		#Create seq summary file from barcoded reads
		Fast5_to_seq_summary --fast5_dir ./final_fast5s_${expName}/${barcodesOfInterest[${i}]} \
		--threads 30 \
		--seq_summary_fn ./sequencing_summary_${barcodesOfInterest[${i}]}.txt

		#Perform pycoQC analysis
		pycoQC -f ./sequencing_summary_${barcodesOfInterest[${i}]}.txt -o ./pycoQC_${barcodesOfInterest[${i}]}.html

		cp ./pycoQC_${barcodesOfInterest[${i}]}.html ${work_DIR}/output/.
	fi
fi


conda deactivate