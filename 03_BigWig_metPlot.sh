#! /bin/bash
  
## Allocate resources
#SBATCH --time=8-00:00:00
#SBATCH --partition=gpu
#SBATCH --array=0-1
#SBATCH --mem=64G
#SBATCH –-cpus-per-task=8

## job metadata
#SBATCH --job-name="Build_BigWig"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

## #SBATCH --array parameter should be CHANGED according to NUMBER OF BARCODES:
## array=0-(total number of barcodes-1)

source ./varSettings.sh

source ${CONDA_ACTIVATE} ${condaEnv}
i=$SLURM_ARRAY_TASK_ID

# Move to scratch temp experiment folder
cd /scratch/TMP_Megalodon_${expName}/megalodon_results_${barcodesOfInterest[${i}]}

# Run Python sqlite DB extraction
python ${work_DIR}/03_Build_BigWig_helper.py ${barcodesOfInterest[${i}]} ${k}

# Build Wigs
chrom=(chrI chrII chrIII chrIV chrM chrV chrX)

for j in $(seq 7); do
	echo variableStep chrom=${chrom[${j}-1]} span=1 >> ${barcodesOfInterest[${i}]}.wig
	cat ${j}.txt >> ${barcodesOfInterest[${i}]}.wig
	echo variableStep chrom=${chrom[${j}-1]} span=1 >> ${barcodesOfInterest[${i}]}_w10.wig
	cat ${j}_w10.txt >> ${barcodesOfInterest[${i}]}_w10.wig
	rm ${j}.txt ${j}_w10.txt
done

# Build BigWigs
fetchChromSizes ce11 > ce11.chrom.sizes
wigToBigWig ${barcodesOfInterest[${i}]}.wig ce11.chrom.sizes ${barcodesOfInterest[${i}]}.bw
wigToBigWig ${barcodesOfInterest[${i}]}_w10.wig ce11.chrom.sizes ${barcodesOfInterest[${i}]}_w10.bw

# Remove intermediary files
rm ${barcodesOfInterest[${i}]}.wig ${barcodesOfInterest[${i}]}_w10.wig ce11.chrom.sizes

conda deactivate