# -*- coding: utf-8 -*-
"""
@author: Ahrmad

functions that can extract reads that cover a particular region of the genome
build a matrix where each row is a read name and each column is a CpG or GpC site
the values are 0-1 probabilites of methylation and nan if no call is available at that site.

single_mol_plot outputs a plot of the region selected
single_mol_mat outputs a tsv of the region selected
"""

import os
import sys
import time
import sqlite3
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from scipy.ndimage.filters import uniform_filter1d

def get_read_scores(db,read_id,strand,motif):

	#Connect to the DB
	conn = sqlite3.connect(db)
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
					INNER JOIN read ON data.score_read = read.read_id \
					WHERE read.uuid = '{read_id}' AND data.score_pos%2 = {strand} ")
	score_list = c.fetchall()

	#Close the connection
	conn.close()

	return score_list


def single_mol_plot(chrm,low,high,min_len=1,db='per_read_modified_base_calls.db',roi='ROI.txt',k=0.7):

	'''
	Input:  chrm:chromosome of interest
			low & high: lower & higher limit of the region of interest
			min_len:minimum read length (optional)
	Outputs:txt file with read_ids and strand
	'''

	start = time.time()
	os.system(f"samtools view mappings.sorted.bam '{chrm}:{low}-{high}' | awk '{{if (length($10)>{min_len}) print $0}}' | awk '{{if ($2==16) print $1,1; else print $1,0}}' > {roi}")
	print(f'Samtools extraction of reads >{min_len}bp in region {chrm}:{low}-{high} {(time.time() - start):0.2f} seconds')

	ROIs = np.genfromtxt(roi,dtype='U',delimiter=' ',skip_header=0)

	## C. elegans
	chrom_list=['chrI','chrII','chrIII','chrIV','chrM','chrV','chrX']
	CumSumLen=[0,15072434,30351855,44135656,61629485,61643279,82567459,100286401]
	offset = CumSumLen[chrom_list.index(chrm)]

	fig, (ax1, ax2) = plt.subplots(nrows=2, sharex=True, subplot_kw=dict(frameon=False),gridspec_kw={'height_ratios': [1, 4]})
	plt.subplots_adjust(hspace=.0)
	ax1.grid(alpha=0.4)
	ax1.set_ylim(0,1)
	ax1.set_yticks([0,0.2,0.4,0.6,0.8,1])
	ax1.set_ylabel('dSMF')
	ax2.set_ylabel('Single Molecules')
	#ax2.yaxis.set_ticklabels([])
	ax2.xaxis.set_major_formatter(mticker.ScalarFormatter())
	ax2.xaxis.get_major_formatter().set_scientific(False)
	ax2.xaxis.get_major_formatter().set_useOffset(False)
	plt.xlabel(chrm)

	Tot_time = 0
	print(f'Starting DB query of {ROIs.shape[0]} reads')
	for i,read in enumerate(ROIs):
		start = time.time()
		
		#score_list = np.array(get_read_scores(db,read[0],int(read[1]),motif='GCG'))
		motifs = ['HCG','GCH','GCG']
		score_list = []
		for motif in motifs:
			score_list = score_list + get_read_scores(f'./s16.{motif}_1/per_read_modified_base_calls.db',read[0],int(read[1]),motif)
		score_list = np.array(score_list)

		print(f'DB Query {i+1}/{ROIs.shape[0]}, read_id:{read[0]} in {(time.time() - start):0.2f} seconds')#\r',end=''
		Tot_time += (time.time() - start)
		score_list[:,1] = np.exp(score_list[:,1])

		score_list[:,0] = score_list[:,0] - offset
		pos_indices = (score_list[:,0] >= low) & (score_list[:,0] <= high)
		score_list = score_list[pos_indices]

		if score_list.size==0:
			print('read containing no CG/GC motifs within bounds')
			continue

		if i==0:
			FSL = score_list
		else:
			FSL = np.vstack((FSL, score_list))

		met_indices = (score_list[:,1] >= k)
		met_list = score_list[:,0][met_indices]

		#unmet_indices = (score_list[:,1] < k)
		#unmet_list = score_list[:,0][unmet_indices]

		ax2.hlines(i, int(np.min(score_list[:,0])), int(np.max(score_list[:,0])), colors='k', linestyles='solid',linewidth=2.0,alpha=0.2)
	
		for sc in met_list:
			ax2.hlines(i, int(sc)-1, int(sc)+1, colors='k', linestyles='solid',linewidth=4.0,alpha=1)
		
		#for sc in unmet_list:
		#	ax2.hlines(i, int(sc)-5, int(sc)+5, colors='blue', linestyles='solid',linewidth=4.0,alpha=0.2)

	print(f'Total Query time: {(Tot_time//60)+1} mins')
	start = time.time()

	FSL[:,1] = 1 - FSL[:,1]

	#Apply threshold, all values above threshold will be 1s, under will be 0s
	FSL[:,1] = FSL[:,1] > (1 - float(k))
	#Group by position
	unqa,ID,counts = np.unique(FSL[:,0],return_inverse=True,return_counts=True)
	FSL = np.column_stack(( unqa , np.bincount(ID,FSL[:,1])/counts ))
	#Rolling window average
	FSL[:,1] = uniform_filter1d(FSL[:,1], size=10)

	print(f'Build dSMF track {(time.time() - start):0.2f} seconds')

	ax1.plot(FSL[:,0],FSL[:,1], color='k', linestyle='solid',linewidth=0.4, alpha=0.8)
	#ax1.fill_between(FSL[:,0],FSL[:,1], color='xkcd:crimson', alpha=0.3)

	plt.tight_layout()
	plt.savefig(f'single_mol.pdf')
	#plt.show()

	return 0

def single_mol_mat(chrm,low,high,min_len=1,db='per_read_modified_base_calls.db',roi='ROI.txt'):

	'''
	Input:  chrm:chromosome of interest
			low & high: lower & higher limit of the region of interest
			db & roi: filenames of megalodon 
			min_len:minimum read length (optional)
	Outputs:txt file with read_ids and strand
	'''

	start = time.time()
	os.system(f"samtools view mappings.sorted.bam '{chrm}:{low}-{high}' | awk '{{if (length($10)>{min_len}) print $0}}' | awk '{{if ($2==16) print $1,1; else print $1,0}}' > {roi}")
	print(f'Samtools extraction of reads >{min_len}bp in region {chrm}:{low}-{high} {(time.time() - start):0.2f} seconds')

	ROIs = np.genfromtxt(roi,dtype='U',delimiter=' ',skip_header=0)

	## C. elegans
	chrom_list=['chrI','chrII','chrIII','chrIV','chrM','chrV','chrX']
	CumSumLen=[0,15072434,30351855,44135656,61629485,61643279,82567459,100286401]
	offset = CumSumLen[chrom_list.index(chrm)]
	
	FSLA_pos = np.linspace(low-1,high,(high-low),dtype=np.int32)
	FSLA = np.full((FSLA_pos.size,ROIs.shape[0]+1),np.nan, dtype=np.float64)
	FSLA[:,0] = FSLA_pos
	col1=np.array('read_ids',dtype='U')

	Tot_time = 0
	print(f'Starting DB query of {ROIs.shape[0]} reads')
	for i,read in enumerate(ROIs):
		start = time.time()
		
		#Launch if the per read modified database was not split /!\ It will yield shifted results
		#score_list = np.array(get_read_scores(db,read[0],int(read[1]),motif='GCG'))

		motifs = ['HCG','GCH','GCG']
		score_list = []
		for motif in motifs:
			score_list = score_list + get_read_scores(f'./s16.{motif}_1/per_read_modified_base_calls.db',read[0],int(read[1]),motif)
		score_list = np.array(score_list)

		print(f'DB Query {i+1}/{ROIs.shape[0]}, read_id:{read[0]} in {(time.time() - start):0.2f} seconds')#\r',end=''
		Tot_time += (time.time() - start)
		score_list[:,1] = np.exp(score_list[:,1])
		score_list[:,0] = score_list[:,0] - offset
		
		pos_indices = (score_list[:,0] >= low) & (score_list[:,0] <= high)
		score_list = score_list[pos_indices]
		score_list = score_list[score_list[:,0].argsort()]
		
		col1 = np.vstack((col1, read[0]))
		FSLA[np.searchsorted(FSLA[:,0], score_list[:,0], side='left'),i+1]=score_list[:,1]
		
	idx_del = [pos for pos in range(1,FSLA_pos.size) if np.all(np.isnan(FSLA[pos,1:]))]
	FSLA = np.delete(FSLA, idx_del, 0)

	fin = np.array(FSLA.T,dtype='U')
	fin[:,0] = col1[:,0]

	np.savetxt(f"sing_mat.tsv", fin, fmt="%s", delimiter="\t")
	return 0


if __name__ == "__main__":

	#Example with EEF-1A
	#chrm='chrIII'
	#low=6970139
	#high=6971680
	#min_len=500

	#Example with larger region around EEF-1A
	#chrm='chrIII'
	#low=6968631
	#high=6972792

	chrm = sys.argv[1]
	low = int(sys.argv[2])
	high = int(sys.argv[3])

	single_mol_plot(chrm,low,high,min_len=500,db='per_read_modified_base_calls.db',roi='ROI.txt',k=0.7)
	single_mol_mat(chrm,low,high,min_len=500)




