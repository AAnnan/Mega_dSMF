# Mega_dSMF
Analysing nanopore sequencing of dSMF data with [ONT's Megalodon](https://github.com/nanoporetech/megalodon)

## Installation
1) Log on the **GPU** node (IZBDelhi). This is important to make use of the faster scratch folder. Make sure that you have Conda installed with `conda --version`
2) `git clone https://github.com/AAnnan/Mega_dSMF`
3) Review carefully `varSettings.sh` and update the variables according to your data.
4) Launch the install of the Mega_dSMF conda environment with `bash 00_Setup.sh`, you will be asked to input Guppy's latest version. You can check it here: https://community.nanoporetech.com/downloads/guppy/release_notes

## Usage
Launch the scripts **GPU** node (IZBDelhi) with `sbatch` in numerical order. Alternatively, after installing the Mega_dSMF conda environment with `bash 00_Setup.sh`, you can launch the whole pipeline with `bash Mega_wrapper.sh`.

## /!\ One or Two-pass Demultiplexing
To demultiplex your raw reads with `01a_Demux_DeepBinner.sh`, you must have used one of these sequencing/barcoding kits: EXP-NBD103, EXP-NBD104 or very similar. If you have used a different kit, skip `01a_Demux_DeepBinner.sh` and demultiplex only with Guppy by setting the variable `two_pass` to `no` in `varSettings.sh`.

## Output
Outputs will be in a folder named `output` in the Mega_dSMF folder.

Running all scripts (in order) will output:
1) 2-pass (DeepBinner + Guppy Barcoder) or 1-pass (Guppy Barcoder) demultiplexed, basecalled, multifast5s. 
2) All Megalodon outputs listed [here](https://github.com/nanoporetech/megalodon#outputs) and in `Megalodon_Output_Notes.txt` and selected in `varSettings.sh`
3) 2 BigWig files per barcode of **1-Methylated Fraction** along the genome (raw and smoothed with a 10-bp rolling window).
4) 3 plots per barcode of the probability distribution of methylation per motif (dSMF, CpG & GpC).

## Remarks
- 2 sites (GC and CG) will be explored for 5mC through 3 non-overlapping motifs: HCG, GCH and GCG. You can change this directly in `02_Megalodon.sh` according to the information in `varSettings.sh`.
- To keep the efficient arraying of SLURM jobs without needing to manually change the number of SLURM arrays in 3 scripts (`01b_Demux_Guppy.sh`, `02_Megalodon.sh` and `03_BigWig_metPlot.sh`), these 3 scripts will run on 24 (max. number of barcodes for non-bacterial samples) jobs by default, the jobs with no correct barcodes will terminate immediately with no output.

