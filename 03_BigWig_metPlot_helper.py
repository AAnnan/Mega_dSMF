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

def get_scores(per_read_db_file):
	"""
	Input:  per-read db location (str)
	Ouput:  List with scores only, unexp
	"""
	#Connect to the DB
	conn = sqlite3.connect(per_read_db_file)
	c = conn.cursor()

	#Query the database for scores
	c.execute(f"SELECT score FROM data")
	score_l = c.fetchall()

	#Close the connection
	conn.close()

	return np.exp(score_l, dtype=np.float64)

def save_methyl_prob_plot(scores,motif,lib,k):
	"""
	Input:  scores list or numpy array containing unlogged scores (0-1)
			lib name of the library for the plot title (str)
			motif motif searched corresponding to the score list (str)
			k threshold chosen (str or float)
	Ouput:  Pdf plot of the site counts per methylation probability
	"""

	score_count = np.array(np.unique(scores, return_counts=True)).T

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
	
	plt.savefig(f'{lib}_{k}_{motif}_methyl_distribution.pdf')

	plt.close()

	return 0
	
def save_agg_freq_plot(score_list_pos,motif,lib,k):
	"""
	Input:  score_list binarized with threshold all values above threshold are 1s, under 0s
			lib name of the library for the plot title (str)
			k threshold chosen (str or float)
	Ouput:  Pdf plot of the position (not site!) counts freq per methylation probability
	"""

	score_list_pos[:,1] = 1 - np.exp(score_list_pos[:,1])

	#Apply threshold, all values above threshold will be 1s, under will be 0s
	score_list_pos[:,1] = score_list_pos[:,1] > (1 - float(k))

	unqa,ID,counts = np.unique(score_list_pos[:,0],return_inverse=True,return_counts=True)
	out = np.column_stack(( unqa , np.bincount(ID,score_list_pos[:,1])/counts ))

	plt.hist(out[:,1], bins=40, density=True)

	plt.ylabel(f'Frequency (%)')
	plt.xlabel('Methylated/Coverage')
	plt.title(f'{lib} dSMF')

	plt.tight_layout()
	plt.savefig(f'{lib}_{k}_{motif}_agg_freq.pdf')
	plt.close()

	return 0

def main():

	########################################################################
	###########################Build Score Lists############################
	########################################################################
	print(f'Querying Single Molecule Database...')

	motifs = ['HCG','GCH','GCG']
	strands = [0, 1]
	score_list = []

	for motif in motifs:
		for strand in strands:
			print(f'Retrieving scores from {lib}: {motif} strand {strand}...')
			score_list.append(np.array(get_score_list_per_motif(f'./{lib}.{motif}_1/per_read_modified_base_calls.db',strand,motif),dtype=np.float64))
	
	print(f'Building Score Lists...')

	#Motif-spe scores
	score_list_HCG = np.vstack((score_list[0],score_list[1]))
	score_list_GCH = np.vstack((score_list[2],score_list[3]))
	score_list_GCG = np.vstack((score_list[4],score_list[5]))

	#All scores
	log_sc = np.vstack((score_list_HCG,score_list_GCH,score_list_GCG))

	########################################################################
	##############################Build BigWig##############################
	########################################################################
	print(f'Building chromosome specific WIG...')
	
	#Cumulative length
	cumsum_chrm_lens = np.cumsum(chrm_lens)

	#Transform the scores to get 1-fraction methylated
	unlog_sc = np.copy(log_sc)
	unlog_sc[:,1] = 1 - np.exp(unlog_sc[:,1])

	#Apply threshold, all values above threshold will be 1s, under will be 0s
	unlog_sc[:,1] = unlog_sc[:,1] > (1 - float(k))

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

	print(f'All WIGs done.\n')
	########################################################################
	#########################Build Methyl Plots#############################
	########################################################################
	print(f'Building Methylation Distribution Plots...')
	
	print(f'dSMF...')
	save_methyl_prob_plot(np.exp(log_sc[:,1]),'CpG_GpC',lib,k)
	print(f'CpG...')
	save_methyl_prob_plot(np.exp(score_list_HCG[:,1]),'CpG',lib,k)
	print(f'GpC...')
	save_methyl_prob_plot(np.exp(score_list_GCH[:,1]),'GpC',lib,k)

	print(f'Building Aggregate Methylation Frequency Plot...')
	print(f'dSMF...')
	save_agg_freq_plot(log_sc,'CpG_GpC',lib,k)
	print(f'CpG...')
	save_agg_freq_plot(score_list_HCG,'CpG',lib,k)
	print(f'GpC...')
	save_agg_freq_plot(score_list_GCH,'GpC',lib,k)

	print(f'Plots built.')

if __name__ == "__main__":
	main()
