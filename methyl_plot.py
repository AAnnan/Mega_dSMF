# -*- coding: utf-8 -*-
"""
@author: Ahrmad

Builds a Barplot from Megalodon's per_read_modified_base_calls.txt output.
On the right of the dotted line are methylated motifs.
"""

import sys
import numpy as np
from collections import Counter
import matplotlib.pyplot as plt

exp = sys.argv[1]

###Open txt output from Megalodon: per_read_modified_base_calls
calls = np.genfromtxt('per_read_modified_base_calls.txt', delimiter='\t',skip_header=1).astype(np.float32)

#Store 4th (mod_log_prob) and 5th (can_log_prob)
mod = calls[:,4]
can = calls[:,5]

#Get log ratio of mod_prob/can_prob
# will be a list of HCG, GCH or CGC motifs with their methylation score
meth_scores = mod-can

####Count occurences of all obtained scores
agg_scores = Counter(meth_scores)

###BarPlot scores on Y and number of sites (HCG, GCH or CGC) having obtained that score on X
plt.bar(agg_scores.keys(), agg_scores.values(), align='center', width=0.05)
plt.xlim([min(meth_scores), max(meth_scores)])

plt.axvline(x=0.875, color='r', linestyle='--',label='Threshold=0.875')
plt.legend(loc='upper right',fontsize='small')

plt.xlabel('log(probability of modified base/probability of canonical base)')
plt.ylabel('GCG HCG GCH Count')

plt.title(exp)
plt.savefig(f'{exp}_methyl_plot.pdf')