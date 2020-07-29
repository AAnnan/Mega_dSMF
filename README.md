# Mega_dSMF
Analysing nanopore sequencing of dSMF data with Megalodon

## Installation
1) Log in the GPU node (IZBDelhi). This is important to make use of the faster scratch folder.
2) `git clone https://github.com/AAnnan/Mega_dSMF`
3) launch setup.sh, you will be asked to input Guppy's latest version. You can check it here: https://community.nanoporetech.com/downloads/guppy/release_notes

## Remarks
- To demultiplex your raw reads with 01_Demultiplex.sh, you have to have used one of these sequencing/barcoding kit: EXP-NBD103, EXP-NBD104 or very similar.

- 3 motifs (GCG, HCG, GCH) will be explored for 5mC (H is any base except G). Refer to varSettings.sh if you wish to modify this.
