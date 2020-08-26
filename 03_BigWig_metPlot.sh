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
lib=${barcodesOfInterest[${i}]}

# Move to scratch temp experiment folder
cd /scratch/TMP_Megalodon_${expName}/megalodon_results_${lib}

# Run Python sqlite DB extraction
python ${work_DIR}/03_BigWig_metPlot_helper.py ${lib} ${k}

# Build Wigs
chrom=(chrI chrII chrIII chrIV chrM chrV chrX)

for j in $(seq 7); do
	echo variableStep chrom=${chrom[${j}-1]} span=1 >> ${lib}.wig
	cat ${j}.txt >> ${lib}.wig
	echo variableStep chrom=${chrom[${j}-1]} span=1 >> ${lib}_w10.wig
	cat ${j}_w10.txt >> ${lib}_w10.wig
	rm ${j}.txt ${j}_w10.txt
done

# Build BigWigs
fetchChromSizes ce11 > ce11.chrom.sizes
wigToBigWig ${lib}.wig ce11.chrom.sizes ${lib}.bw
wigToBigWig ${lib}_w10.wig ce11.chrom.sizes ${lib}_w10.bw

# Remove intermediary files
rm ${lib}.wig ${lib}_w10.wig ce11.chrom.sizes

conda deactivate