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

exp = sys.argv[1]

###Open txt output from Megalodon: per_read_modified_base_calls
with open('per_read_modified_base_calls.txt') as csvfile: 
	calls = csv.reader(csvfile, delimiter='\t')

	#jump header
	next(calls, None)

	#Store log mod_log_prob/can_log_prob columns into a list
	meth_scores = [float(row[4])-float(row[5]) for row in calls]

####Count occurences of all obtained scores
agg_scores = Counter(meth_scores)

###BarPlot scores on Y and number of sites having obtained that score on X
plt.bar(agg_scores.keys(), agg_scores.values(), align='center', width=0.05)
plt.xlim([min(meth_scores), max(meth_scores)])
#plt.ylim(0, 10000)
plt.axvline(x=0.85, color='r', linestyle='--',label='Megalodon threshold')
plt.legend(loc='upper right',fontsize='small')
plt.xlabel('log(probability of modified base/probability of canonical base)')
plt.ylabel(f'Motif Site Count')
plt.title(exp)
plt.savefig(f'{exp}_methyl_plot.pdf')
#plt.show()
