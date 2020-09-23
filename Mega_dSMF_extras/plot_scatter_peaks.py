# -*- coding: utf-8 -*-
"""
@author: Ahrmad

Builds Scatterplots comparing ONLY peak regions in different signals
method = middle_pos will extract regions around peaks for each signal and compare them directly
method = shifted will extract regions around peaks, shift them so that the 2 peaks match exactly and compare them

To run after BigWigToNumpyArray
Edit the bottom of the file

"""

import numpy as np
from scipy import signal,stats
from scipy.ndimage.filters import uniform_filter1d
import matplotlib.pyplot as plt

def get_peaks(scores,prominence=0.4, distance=300):
	'''
	Input: Scores (numyp array), signal.find_peaks settings
	Output: Indices of peaks in Scores
	'''
	scores[:,1] = 1 - scores[:,1]
	
	peaks, p_dic = signal.find_peaks(scores[:,1],prominence=prominence, distance=distance)

	return scores[:,0][peaks]

def get_regions(peaks1,peaks2, window=200,inter_peak_dist=50,method='middle_pos'):
	'''
	Input: 2 list of indices of peaks. window around the peak, inter_peak_dist: dist min between 2 peaks
	window must be higher than inter peak distance
	methods: 'middle_pos' take the peaks1 positions, fetches nearest peaks2 returns the middle windowed regions
			 'shifted'	  take the peaks1 positions, fetches nearest peaks2, returns both regions separately
	Output: Score regions around peaks
	'''

	p2_near_p1 = np.array([ (peak,peaks2[(np.abs(peaks2 - peak)).argmin()]) for peak in peaks1 if np.min(np.abs(peaks2 - peak))<inter_peak_dist ])

	if method=='middle_pos':

		centers_p1p2 = (p2_near_p1[:,0] + p2_near_p1[:,1])//2
		regions = np.stack((centers_p1p2 - window//2, centers_p1p2 + window//2), axis=-1)
		return regions, regions

	elif method=='shifted':
		p1 = p2_near_p1[:,0]
		p2 = p2_near_p1[:,1]
		regions1 = np.stack((p1 - window//2, p1 + window//2), axis=-1)
		regions2 = np.stack((p2 - window//2, p2 + window//2), axis=-1)
		return regions1, regions2

def corr_peaks(scores1,scores2,min_nb_pts=20,method='middle_pos'):
	'''
	Input: Scores (numpy arrays), min_nb_pts: lowest number of points in a region, method: see above
	Output: A Scatterplot showing average regional correlation between the 2 signals, comparing only their peak regions.
	'''
	peaks1 = get_peaks(scores1,prominence=0.4, distance=300)
	peaks2 = get_peaks(scores2,prominence=0.4, distance=300)

	reg1,reg2 = get_regions(peaks1,peaks2,method,window=300,inter_peak_dist=50)

	sig1 = []
	sig2 = []
	nb_pts =0
	w=1
	for p in range(len(reg1)):
		print(f' {p} peaks:{nb_pts} pts {p/len(reg1):.2%}\r',end='')

		score_reg1 = scores1[ (scores1[:,0]> reg1[p][0]) & (scores1[:,0]< reg1[p][1]) ]
		score_reg2 = scores2[ (scores2[:,0]> reg2[p][0]) & (scores2[:,0]< reg2[p][1]) ]

		nb_pts = (score_reg1.size + score_reg2.size)//2

		if nb_pts < min_nb_pts or score_reg1.size < min_nb_pts or score_reg2.size < min_nb_pts:
			print(f'Weak Peak {w}|{nb_pts}|{score_reg1.size}|{score_reg2.size}           ')
			w+=1
			continue

		x1 = np.linspace(np.min(score_reg1[:,0]),np.max(score_reg1[:,0]),nb_pts,dtype=np.int32)
		x2 = np.linspace(np.min(score_reg2[:,0]),np.max(score_reg2[:,0]),nb_pts,dtype=np.int32)

		y1 = np.interp(x1, score_reg1[:,0], score_reg1[:,1])
		y2 = np.interp(x2, score_reg2[:,0], score_reg2[:,1])

		sig1 += list(y1.flatten())
		sig2 += list(y2.flatten())

	sig1 = np.array(sig1).flatten()
	sig2 = np.array(sig2).flatten()

	slope, intercept, r_value, p_value, std_err = stats.linregress(sig1,sig2)

	plt.scatter(sig1,sig2,label=f'r2={r_value:.2f}',alpha=0.1)
	plt.legend(loc='upper left')
	plt.tight_layout()
	#plt.show()
	plt.savefig('scatterPeaks.pdf')

	return 0



if __name__ == "__main__":

	#Change name according to your data
	scores1 = np.load('w10smDSMF_dS16N2gw.npy')
	scores2 = np.load('w10smDSMF_dS16mg.npy')

	#method='shifted'
	corr_peaks(scores1,scores2,method='middle_pos')


