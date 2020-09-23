#! /bin/bash
  
## Allocate resources
#SBATCH --time=00:60:00
#SBATCH --partition=gpu
#SBATCH --mem=64G
#SBATCH –-cpus-per-task=8

## job metadata
#SBATCH --job-name="03"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

source ${CONDA_ACTIVATE} Mega_dSMF
dir=${PWD##*/}

read -p 'Name of BedMethyl File (Output from Megalodon)' bedfile

for strand in - ; do
	for chrom in chrV chrX chrIV chrII chrI chrIII chrM; do
		awk -v strand="${strand}" -v chrom="${chrom}" '$5!=0 && $1==chrom && $6==strand {print $2,$11,$10}' ${bedfile} >> ${chrom}${strand}.wig
	done
done

for strand in + ; do
	for chrom in chrV chrX chrIV chrII chrI chrIII chrM; do
		awk -v strand="${strand}" -v chrom="${chrom}" '5!=0 && $1==chrom && $6==strand {print $2+1,$11,$10}' ${bedfile} >> ${chrom}${strand}.wig
	done
done

for chrom in chrV chrX chrIV chrII chrI chrIII chrM; do
	awk 'NR==FNR{a[$1];next} !($1 in a){print $1,$2}' ${chrom}+.wig ${chrom}-.wig >> ${chrom}.wig
	awk 'NR==FNR{a[$1];next} !($1 in a){print $1,$2}' ${chrom}-.wig ${chrom}+.wig >> ${chrom}.wig
	awk 'NR==FNR{a[$1]=$2;b[$1]=$3;next} ($1 in a){print $1,((a[$1]*b[$1] + $2*$3)/($3+b[$1]))}' ${chrom}-.wig ${chrom}+.wig >> ${chrom}.wig
done

for chrom in chrV chrX chrIV chrII chrI chrIII chrM; do
	echo variableStep chrom=${chrom} span=1 >> ${dir}_tmp.wig
	cat ${chrom}.wig >> ${dir}_tmp.wig
done

awk '{if ($2 ~/^[0-9]+\.?[0-9]*$/) print $1,1-($2/100); else print $0}' ${dir}_tmp.wig > ${dir}.wig

fetchChromSizes ce11 > ce11.chrom.sizes
wigToBigWig ${dir}.wig ce11.chrom.sizes ${dir}.bw

rm *.wig ce11.chrom.sizes
conda deactivate
