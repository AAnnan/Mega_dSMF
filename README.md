# Mega_dSMF
Analysing nanopore sequencing of dSMF data with Megalodon

## Installation
1) Log in the **GPU** node (IZBDelhi). This is important to make use of the faster scratch folder. Make sure that you have Conda installed with `conda --version`
2) `git clone https://github.com/AAnnan/Mega_dSMF`
3) Review carefully `varSettings.sh` and update the variables according to your data.
4) launch installation with `bash 00_Setup.sh`, you will be asked to input Guppy's latest version. You can check it here: https://community.nanoporetech.com/downloads/guppy/release_notes

## Usage
Before launching the first script: 
- Set #SBATCH --array to "0-(number of barcodes-1)" in the SLURM resource allocation part of the following scripts: `01b_Demux_Guppy.sh`, `02_Megalodon.sh` and `03_BigWig_metPlot.sh`.
- To demultiplex your raw reads with `01a_Demux_DeepBinner.sh`, you must have used one of these sequencing/barcoding kits: EXP-NBD103, EXP-NBD104 or very similar. If you have used a different kit, skip `01a_Demux_DeepBinner.sh` and demultiplex directly with `01b_Demux_Guppy.sh`. You will have to update `varSettings.sh` accordingly.

Run the scripts on the cluster with `sbatch` in numerical order. 

## Output
Outputs will be in a folder named `output` in the Mega_dSMF folder.

Running all scripts (in order) will output:
1) 2-pass or 1-pass demultiplexed, basecalled, multifast5s. 
2) All outputs listed in `Megalodon_Output_Notes.txt` and selected in `varSettings.sh`
3) BigWig files of (1-Methylates Fraction) along the genome.
4) PDFs barplots of the distribution of methylation probabilities per C site, within a barcode.

## Remarks
- 2 sites (GC and CG) will be explored for 5mC through 3 non-overlapping motifs: HCG, GCH and GCG. You can change this directly in `02_Megalodon.sh` according to the information in `varSettings.sh`.

