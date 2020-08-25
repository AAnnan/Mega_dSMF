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

### Global Variables
mega_folder = sys.argv[1]
lib = sys.argv[2] #${barcodesOfInterest[${i}]}
k = sys.argv[3]
motifs = ['GCG','HCG','GCH']

def get_score_list_per_motif(per_read_db_file,strand,motif):
	"""
	Input:  per-read db
			Strand (0=FWD 1=REV)
			Motif ('GCG','HCG','GCH')
	Ouput:  List each motif position with its associated score
			shape:(#ofmotifsites,2), 0 are positions in absolute form, 1 are scores in ln
	"""

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
	conn.close()

	return score_list

strands = [0, 1]
score_list = []
##Retrieve the whole score list (pos,score) from the DBs
for motif in motifs:
	for strand in strands:
		score_list = score_list + get_score_list_per_motif(f'{mega_folder}/{lib}.{motif}_1/per_read_modified_base_calls.db',strand,motif)

#Store in Numpy array, transform the scores to get 1-fraction methylated
unlog_sc = np.array(score_list,dtype=np.float64)
unlog_sc[:,1] = 1 - np.exp(unlog_sc[:,1])

#Apply threshold, all values above threshold will be 1s, under will be 0s
unlog_sc[:,1] = unlog_sc[:,1] > (1 - float(k))

#Length of CE chromosomes in order (chrI chrII chrIII chrIV chrM chrV chrX)
chrm_lens = [0,15072434,15279421,13783801,17493829,13794,20924180,17718942]
#Cumulative length
cumsum_chrm_lens = np.cumsum(chrm_lens)

#Retrieve data for each chromosome
for cl in range(1,len(chrm_lens)):

	#Select chromosome-specific scores
	mask_split1 = unlog_sc[:,0] > cumsum_chrm_lens[cl-1]
	unlog_sc_split1 = unlog_sc[mask_split1]
	mask_split2 = unlog_sc_split1[:,0] <= cumsum_chrm_lens[cl]
	unlog_sc_split2 = unlog_sc_split1[mask_split2]

	unlog_sc_split2[:,0] = unlog_sc_split2[:,0] - cumsum_chrm_lens[cl-1]

	#Aggregate per position with average
	unlog_sc_unq = pd.DataFrame(unlog_sc_split2).groupby(0).mean()
	#Apply a 10-base rolling window average
	unlog_sc_unq_rwa = unlog_sc_unq.rolling(10,min_periods=1).mean()
	#Output to txt
	unlog_sc_unq.to_csv(path_or_buf=f'{cl}.txt',sep=' ', header=False)
	unlog_sc_unq_rwa.to_csv(path_or_buf=f'{cl}_w10.txt',sep=' ', header=False)