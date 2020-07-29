# Mega_dSMF
Analysing nanopore sequencing of dSMF data with Megalodon

## Installation
1) Log in the GPU node (IZBDelhi). This is important to make use of the faster scratch folder.
2) `git clone https://github.com/AAnnan/Mega_dSMF`
3) launch setup.sh, you will be asked to input Guppy's latest version. You can check it here: https://community.nanoporetech.com/downloads/guppy/release_notes
4) Run the scripts in numerical order. Outputs will be in the same folder.
## Remarks
- To demultiplex your raw reads with 01_Demultiplex.sh, you have to have used one of these sequencing/barcoding kit: EXP-NBD103, EXP-NBD104 or very similar.

- 3 motifs (GCG, HCG, GCH) will be explored for 5mC (H is any base except G). Refer to varSettings.sh if you wish to modify this.

## Output

Running all 3 scripts (in order) will output:

1) Demultiplexed raw multiFast5
2) All outputs listed in `Megalodon_Output_Notes.txt`
3) PDFs showing Barplots of the proportion of methylated motif sites within a barcode
