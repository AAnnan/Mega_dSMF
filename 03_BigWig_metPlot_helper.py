# -*- coding: utf-8 -*-
"""
@author: Ahrmad

To be used with accompanying SBATCH bash script.
Input: the megalodon result folder with the split_motif subfolders (containing the per read database)
		a library name 
		a probability threshold k (0-1) used for aggregation (above that threshold, a base will be considered methylated)
Output: 2 text files per chr with positions and aggregated methylation scores
"""

import sys
import sqlite3
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.ndimage.filters import uniform_filter1d


### Global Variables
lib = sys.argv[1] #${barcodesOfInterest[${i}]}
k = sys.argv[2]
motifs = ['HCG','GCH','GCG']

#Length of CE chromosomes in order (chrI chrII chrIII chrIV chrM chrV chrX)
chrm_lens = [0,15072434,15279421,13783801,17493829,13794,20924180,17718942]

### Functions
def get_score_list_per_motif(per_read_db_file,strand,motif):
	"""
	Input:  per-read db location (str)
			Strand (0=FWD 1=REV) (int)
			Motif ('GCG','HCG','GCH') (str)
	Ouput:  List each motif position with its associated score
			shape:(#ofmotifsites,2), 0 are positions in absolute form, 1 are scores in ln
	"""

	#Connect to the DB
	conn = sqlite3.connect(per_read_db_file)
	c = conn.cursor()

	#Set positional offset on reverse strands according to motif
	if strand == 0 or motif == 'GCG':
		offset = 0
	elif strand == 1 and motif == 'HCG':
		offset = -1
	elif strand == 1 and motif == 'GCH':
		offset = +1

	#Query the database, applying the position offset when needed
	c.execute(f"SELECT (score_pos/2)+{offset},score \
					FROM data \
					WHERE data.score_pos%2 = {strand}")
	score_list = c.fetchall()

	#Close the connection
	conn.close()

	return score_list

def save_methyl_prob_plot(score_list,motif,lib,k):
	"""
	Input:  score_list list or numpy array containing unlogged scores (0-1)
			lib name of the library for the plot title (str)
			motif motif searched corresponding to the score list (str)
			k threshold chosen (str or float)
	Ouput:  Pdf plot of the site counts per methylation probability
	"""

	score_count = np.array(np.unique(score_list, return_counts=True)).T

	xvals = np.linspace(0, 1, 50)
	scores = np.interp(xvals, score_count[:,0], score_count[:,1])
	scores = uniform_filter1d(scores, size=3)
	scores = list(scores/np.sum(scores))
	scores[0]=0 ; scores[-1]=0

	##Build Plot
	#BarPlot scores on X and the number of motifs having obtained that score on Y
	plt.plot(xvals, scores)
	plt.fill_between(xvals,scores, alpha=0.2)

	plt.axvline(x=float(k), color='r', linestyle=(0, (3, 10, 1, 10)),label=f'Threshold={float(k)}')
	
	plt.legend(loc='upper left',fontsize='small')
	plt.ylabel(f'Fraction of {motif} Sites')
	plt.xlabel('Methylation probability')
	plt.title(f'{lib} dSMF')
	
	plt.savefig(f'{lib}_{k}_methyl_distribution.pdf')

	plt.close()

	return 0
	

def main():

	########################################################################
	##############################Build BigWig##############################
	########################################################################

	strands = [0, 1]
	score_list = []
	##Retrieve the whole score list (pos,score) from the DBs
	for motif in motifs:
		for strand in strands:
			print(f'Retrieving the score list from {lib}: {motif}...')
			score_list = score_list + get_score_list_per_motif(f'./{lib}.{motif}_1/per_read_modified_base_calls.db',strand,motif)
	print(f'Score List Built.')
	#Store in Numpy array
	log_sc = np.array(score_list,dtype=np.float64)
	#Transform the scores to get 1-fraction methylated
	unlog_sc = np.copy(log_sc)
	unlog_sc[:,1] = 1 - np.exp(unlog_sc[:,1])

	#Apply threshold, all values above threshold will be 1s, under will be 0s
	unlog_sc[:,1] = unlog_sc[:,1] > (1 - float(k))

	#Cumulative length
	cumsum_chrm_lens = np.cumsum(chrm_lens)

	print(f'Building chromosome specific WIG')
	#Retrieve data for each chromosome
	for cl in range(1,len(chrm_lens)):
		print(f'Chrom {cl}...')

		#Select chromosome-specific scores
		unlog_sc_perChr = unlog_sc[ (unlog_sc[:,0]>cumsum_chrm_lens[cl-1]) & (unlog_sc[:,0]<=cumsum_chrm_lens[cl]) ]
		unlog_sc_perChr[:,0] = unlog_sc_perChr[:,0] - cumsum_chrm_lens[cl-1]

		#Aggregate per position with average
		unlog_sc_unq = pd.DataFrame(unlog_sc_perChr).groupby(0).mean()
		#Apply a 10-base rolling window average
		unlog_sc_unq_rwa = unlog_sc_unq.rolling(10,min_periods=1).mean()
		#Output to txt
		unlog_sc_unq.to_csv(path_or_buf=f'{cl}.txt',sep=' ', header=False)
		unlog_sc_unq_rwa.to_csv(path_or_buf=f'{cl}_w10.txt',sep=' ', header=False)
	print(f'All WIGs done.')

	########################################################################
	##########################Build Methyl Plot#############################
	########################################################################

	print(f'Building Methylation Distribution Plot...')
	save_methyl_prob_plot(np.exp(log_sc[:,1]),'CpG_GpC',lib,k)
	print(f'Plot built.')

if __name__ == "__main__":
	main()
