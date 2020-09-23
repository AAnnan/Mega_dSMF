# -*- coding: utf-8 -*-
"""
@author: Ahrmad

Builds Scatterplots to compare different signals of the same data
To run after BigWigToNumpyArray
Edit the bottom of the file
"""

from scipy import stats
import numpy as np
from itertools import permutations
import matplotlib.pyplot as plt


def get_wig_scores(wig_arrA,wig_arrB,tile_size,log2):

	len_geno = 100000000
	nb_points = len_geno//tile_size
	tile_pos = np.linspace(1, len_geno, nb_points)

	tile_scoresA = np.interp(tile_pos, wig_arrA[:,0], wig_arrA[:,1])
	tile_scoresB = np.interp(tile_pos, wig_arrB[:,0], wig_arrB[:,1])

	if log2:
		tile_scoresA_log = np.log2(tile_scoresA[(tile_scoresA != 0) & (tile_scoresB != 0)])
		tile_scoresB_log = np.log2(tile_scoresB[(tile_scoresA != 0) & (tile_scoresB != 0)])
		return tile_scoresA_log,tile_scoresB_log
	
	else:
		return tile_scoresA,tile_scoresB


def get_wig_scatter(wig_list,tile_size,log2):

	#Permute wigs together. Get a list of unique duo tuples.
	duo_wigs=list(set(tuple([tuple(sorted(list(i))) for i in permutations(wig_list,2)])))

	#Open plot
	scat = plt.figure(figsize=(13,5))

	for k in range(len(duo_wigs)):

		wigA_arr = np.load(f'{duo_wigs[k][0]}.npy')
		#wigA_arr = np.genfromtxt(f'{duo_wigs[k][0]}.wig',dtype=np.float64,delimiter=' ',skip_header=0)
		wigB_arr = np.load(f'{duo_wigs[k][1]}.npy')
		#wigB_arr = np.genfromtxt(f'{duo_wigs[k][1]}.wig',dtype=np.float64,delimiter=' ',skip_header=0)

		tile_scoresA,tile_scoresB = get_wig_scores(wigA_arr,wigB_arr,tile_size,log2)
		print(tile_scoresA)
		print(tile_scoresB)

		slope, intercept, r_value, p_value, std_err = stats.linregress(tile_scoresA, tile_scoresB)

		scat.add_subplot(len(duo_wigs)//3,3,k+1)
		plt.scatter(tile_scoresA,tile_scoresB,label=f'r2={r_value:.2f}',alpha=0.4)
		if log2:
			lo='log2 '
		else:
			lo=''
		plt.xlabel(f'{duo_wigs[k][0]} | {lo}{sig_typ} | tile size={tile_size}bp',fontsize='small')
		plt.ylabel(f'{duo_wigs[k][1]} | {lo}{sig_typ} | tile size={tile_size}bp',fontsize='small')
		plt.title(f'{duo_wigs[k][0]} vs {duo_wigs[k][1]}',fontsize='small')

		plt.legend(loc='upper left',fontsize='small')
		plt.tight_layout()

	#Show plot
	plt.tight_layout()
	plt.show()

	return 0

def get_wig_r2_plot(wig_list, tile_size_list,log2):
	
	#Permute wigs together. Get a list of unique duo tuples.
	duo_wigs=list(set(tuple([tuple(sorted(list(i))) for i in permutations(wig_list,2)])))

	for k in range(len(duo_wigs)):
		wigA_arr = np.load(f'{duo_wigs[k][0]}.npy')
		#wigA_arr = np.genfromtxt(f'{duo_wigs[k][0]}.wig',dtype=np.float64,delimiter=' ',skip_header=0)
		wigB_arr = np.load(f'{duo_wigs[k][1]}.npy')
		#wigB_arr = np.genfromtxt(f'{duo_wigs[k][1]}.wig',dtype=np.float64,delimiter=' ',skip_header=0)
		
		r2s = []
		for size in tile_size_list:
			tile_scoresA,tile_scoresB = get_wig_scores(wigA_arr,wigB_arr,size,log2)
			slope, intercept, r_value, p_value, std_err = stats.linregress(tile_scoresA,tile_scoresB)
			r2s.append(r_value)
		if log2:
			lo='log2 '
		else:
			lo=''
		plt.plot(np.log10(tile_size_list), r2s, linestyle='solid', marker='o',label=f'{lo}{duo_wigs[k][0]} VS {lo}{duo_wigs[k][1]}')

	plt.xlabel('Log10 Tile Sizes')
	plt.ylabel('r2')
	plt.legend(loc='upper left',fontsize='small')
	plt.tight_layout()
	plt.show()

	return 0


if __name__ == "__main__":
	
	tile_size_list =[1000000,100000,10000,1000,100,50,10,5]
	tile_size = 10000
	log2=False #Bool

	####TO CHANGE ACCORDING TO YOUR DATA
	signal_list=['rawDSMF_dS16N2gw', 'rawDSMF_dS16mg',  'rawDSMF_dS16np']

	get_wig_scatter(wig_list,tile_size,log2)
	get_wig_r2_plot(wig_list, tile_size_list,log2)




