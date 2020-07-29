#! /bin/bash

## Allocate resources
#SBATCH --time=8-00:00:00
#SBATCH --partition=gpu
#SBATCH –-cpus-per-task=8

## job metadata
#SBATCH --job-name="03"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

source ./varSettings.sh
source ~/.bashrc
source ${CONDA_ACTIVATE} ${condaEnv}

cd /scratch/TMP_Megalodon_${expName}

for barcode in ${barcodesOfInterest[@]} ; do
	cd /scratch/TMP_Megalodon_${expName}/megalodon_results_${barcode}
	cp ${work_DIR}/methyl_plot.py .

	python methyl_plot.py ${barcode}
	mv *.pdf ../

	rm methyl_plot.py
done

cd /scratch/TMP_Megalodon_${expName}
cp *.pdf ${work_DIR}

conda deactivate
