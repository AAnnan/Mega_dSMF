# -*- coding: utf-8 -*-
"""
@author: Ahrmad

Builds a plot showing peaks
To run after BigWigToNumpyArray
"""

import sys
import numpy as np
from scipy import signal,stats
import matplotlib.pyplot as plt

def plot_peak_wig(scores,left,right,prominence=0.4, distance=300):
	'''
	Function to plot peaks found by signal.find_peaks
	Inputs: scores numpy array, absolute regio (left, right)
	Outputs: a plot of the dSMF graph in this regions with selected peaks
	'''

	scores[:,1] = 1 - scores[:,1]

	scores = scores[ (scores[:,0]>left) & (scores[:,0]<=right) ]
	scores[:,0] = scores[:,0] - 30351855

	peaks, p_dic = signal.find_peaks(scores[:,1],prominence=prominence, distance=distance)

	plt.plot(scores[:,0],scores[:,1])
	plt.plot(scores[:,0][peaks], scores[:,1][peaks], "xr")

	plt.tight_layout()
	#plt.show()
	plt.savefig(f'peakPlot.pdf')

	return 0

def tweak_find_peaks(scores1,scores2,variat):
	'''
	Function to control peak finding attempts according to one variable: variat.
	Variat can be any optional variable of signal.find_peaks
	'''
	scores1[:,1] = 1 - scores1[:,1]
	scores2[:,1] = 1 - scores2[:,1]

	nb_peaks1 = []
	nb_peaks2 = []
	nb = []

	for pro in list(variat):
		print(f'{list(variat).index(pro)/len((list(variat))):.2%}')
		peaks1, l = signal.find_peaks(scores1[:,1],prominence=0.4, distance=400)
		peaks2, ll = signal.find_peaks(scores2[:,1],prominence=0.4, distance=400)
		#signal.find_peaks(x, height=None, threshold=None, distance=None, prominence=None, width=None, wlen=None, rel_height=0.5, plateau_size=None)
		########Tweak find peaks with variat and look at the stat plot
		nb_peaks1.append(peaks1.shape[0])
		nb_peaks2.append(peaks2.shape[0])
		#nb.append(peaks2.shape[0]/peaks1.shape[0])

	plt.plot(variat,nb_peaks1,label='scores1')
	plt.plot(variat,nb_peaks2,label='scores2')
	#plt.plot(variat,nb,label='scores1/scores2')
	
	plt.legend(loc='upper right',fontsize='small')
	plt.tight_layout()
	#plt.show()
	plt.savefig(f'peak_finding.pdf')

	return 0


if __name__ == "__main__":
	print('arg1=chromosome of the region\narg2=lower limit of the region\narg3=higher limit of the region\narg4=absolute path of numpy array containing scores (including filename)')

	chrm = sys.argv[1]
	left = int(sys.argv[2])
	right = int(sys.argv[3])
	scores = sys.argv[4]

	## C. elegans
	chrom_list=['chrI','chrII','chrIII','chrIV','chrM','chrV','chrX']
	CumSumLen=[0,15072434,30351855,44135656,61629485,61643279,82567459,100286401]
	offset = CumSumLen[chrom_list.index(chrm)]
	left += offset
	right += offset

	###TEST
	#scores = np.load('w10smDSMF_dS16mg.npy') #w10smDSMF_dS16mg.npy  w10smDSMF_dS16np.npy w10smDSMF_dS16N2gw
	#left = 4985859+30351855 #In-chrom position + absolute pos of chrom
	#right = 5026239+30351855

	plot_peak_wig(scores,left,right)

	###Tweak
	#variat = np.linspace(20,200,5)
	#tweak_find_peaks(scores1,scores2,variat)

