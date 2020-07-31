# -*- coding: utf-8 -*-
"""
@author: Ahrmad

Builds a Barplot from Megalodon's per_read_modified_base_calls.txt output.
On the right of the dotted line are methylated bases.
Shows the proportion of methylated motif sites within a barcode
"""

import sys
import csv
from collections import Counter
import matplotlib.pyplot as plt

###Open txt output from Megalodon: per_read_modified_base_calls
exp = sys.argv[1]

for file in sys.argv[1:]:
	calls = np.genfromtxt('per_read_modified_base_calls.txt', delimiter='\t',skip_header=1,).astype(np.float32)
	mod = calls[:,4]
	can = calls[:,5]
	
	meth_scores = mod-can

	####Count occurences of all obtained scores
	agg_scores = Counter(meth_scores)

	###BarPlot scores on Y and number of sites having obtained that score on X
	plt.bar(agg_scores.keys(), agg_scores.values(), align='center', width=0.05)
	plt.xlim([min(meth_scores), max(meth_scores)])
	plt.axvline(x=0.85, color='r', linestyle='--',label='Threshold=0.85')
	plt.legend(loc='upper right',fontsize='small')
	plt.xlabel('log(probability of modified base/probability of canonical base)')
	plt.ylabel(f'GCG HCG GCH Count')
	plt.title(file.strip('.txt'))
	plt.savefig(file.strip('.txt')+'_methyl_plot.pdf')