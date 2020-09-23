#! /bin/bash

#Names of BigWigs to transform into numpy arrays (space separated)
bws=(rawDSMF_dS16N2gw s16_k0.85 w10smDSMF_dS16N2gw rawDSMF_dS16np s16_k0.85_w10 w10smDSMF_dS16np)

source ${CONDA_ACTIVATE} Mega_dSMF

#List of C. Elegans chromosomes
chrom=(chrI chrII chrIII chrIV chrM chrV chrX)
#Length of CE chromosomes in order (chrI chrII chrIII chrIV chrM chrV chrX)
#chrm_lens = [0,15072434,15279421,13783801,17493829,13794,20924180,17718942]
#Cumulative length of CE chromosomes
CumSumLen=(0 15072434 30351855 44135656 61629485 61643279 82567459 100286401)

#loop over BWs
for bw in ${bws[@]}; do
	#loop over chromosomes
	for i in $(seq 0 6); do
		#Perform BW to wig
		bigWigToWig ${bw}.bw ${bw}_${chrom[$i]}.wig -chrom=${chrom[$i]}
		awk -v CumSumLen="${CumSumLen[$i]}" '{if ($1 ~/^[0-9]+$/) print $1+CumSumLen,$2}' ${bw}_${chrom[$i]}.wig >> ${bw}.wig
		rm ${bw}_${chrom[$i]}.wig
		echo $bw ${chrom[$i]} done
	done
	#Perform wig to numpy array
	wig=${bw}.wig
	python -c "import numpy as np;np.save('$bw',np.genfromtxt('$wig',dtype=np.float64,delimiter=' ',skip_header=0))"
done

conda deactivate