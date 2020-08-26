# Mega_dSMF
Analysing nanopore sequencing of dSMF data with Megalodon

## Installation
1) Log in the **GPU** node (IZBDelhi). This is important to make use of the faster scratch folder.
2) `git clone https://github.com/AAnnan/Mega_dSMF`
3) launch setup.sh, you will be asked to input Guppy's latest version. You can check it here: https://community.nanoporetech.com/downloads/guppy/release_notes

## Usage
Before launching the first script: 
- Review carefully `varSettings.sh` and update the variables according to your data.
- Set #SBATCH --array to "0-(number of barcodes-1)" in the SLURM resource allocation part of the following scripts: `01b_Demux_Guppy_Refine.sh`, `02_Megalodon.sh` and `03_Build_BigWig.sh`.

Run the scripts on the cluster with `sbatch` in numerical order. 

## Output
Outputs will be in the same folder as the scripts: Mega_dSMF_"expName".

Running all scripts (in order) will output:
1) Finely demultiplexed, basecalled, multifast5s. 
2) All outputs listed in `Megalodon_Output_Notes.txt` and selected in `varSettings.sh`
3) BigWig files of average dSMF all along the genome (1-fraction methylation).

## Remarks
- To demultiplex your raw reads with `01a_Demux_DeepBinner.sh`, you have to have used one of these sequencing/barcoding kit: EXP-NBD103, EXP-NBD104 or very similar.

- 2 motifs (GC and CG) will be explored for 5mC.

