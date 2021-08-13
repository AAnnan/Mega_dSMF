#! /bin/bash
  
## Allocate resources
#SBATCH --time=8-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=128G
#SBATCH –-cpus-per-task=6

## job metadata
#SBATCH --job-name="Build_BigWig"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

source ./varSettings.sh
source ${CONDA_ACTIVATE} ${condaEnv}

# Move to scratch temp experiment folder
cd /scratch/TMP_Megalodon_${expName}/megalodon_results_${expName}

# Run Python sqlite DB extraction
python ${work_DIR}/03_BigWig_metPlot_helper.py ${expName} ${k}

# Build Wigs
chrom=(chrI chrII chrIII chrIV chrM chrV chrX)

echo Formatting WIGS...
for j in $(seq 7); do
	echo Formatting Chrom ${j}
	echo variableStep chrom=${chrom[${j}-1]} span=1 >> ${expName}.wig
	cat ${j}.txt >> ${expName}.wig
	echo variableStep chrom=${chrom[${j}-1]} span=1 >> ${expName}_w10.wig
	cat ${j}_w10.txt >> ${expName}_w10.wig
	rm ${j}.txt ${j}_w10.txt
done
echo Formatting WIGS Done.
echo Building BIGWIGs...

# Build BigWigs
fetchChromSizes ce11 > ce11.chrom.sizes
wigToBigWig ${expName}.wig ce11.chrom.sizes ${expName}.bw
wigToBigWig ${expName}_w10.wig ce11.chrom.sizes ${expName}_w10.bw
echo Building BIGWIGs Done.

echo Remove intermediary files...
# Remove intermediary files
rm ${expName}.wig ${expName}_w10.wig ce11.chrom.sizes

#Remove Copy files to output folder
# Copy files to output folder
cp *.bw *.pdf ${work_DIR}/output/.

conda deactivate