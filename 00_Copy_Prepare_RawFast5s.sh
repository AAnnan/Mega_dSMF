#! /bin/bash
  
## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=32G
#SBATCH –-cpus-per-task=8

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="Copy Raw Fast5"


## Script to move and prepare the raw fast5 before demultiplexing with DeepBinner
## Should be run in the same folder as varSettings.sh
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh
source ~/.bashrc

source ${CONDA_ACTIVATE} ${condaEnv}

# Create and move to a temporary scratch folder
mkdir -p /scratch/TMP_Megalodon_${expName}/rawFast5
cd /scratch/TMP_Megalodon_${expName}

### Get Rerio's research model from GitHub (if it doesn't exist already)
if [[ ! -f ./rerio/basecall_models/res_dna_r941_min_modbases-all-context_v001.cfg ]]
then
	echo "Installing Rerio's modbases all context research model"
    git clone https://github.com/nanoporetech/rerio
	python rerio/download_model.py rerio/basecall_models/res_dna_r941_min_modbases-all-context_v001
fi
# Copy Guppy's barcoding models into Rerio's folder
cp ${GUPPY_DIR}/../data/barcoding/* ./rerio/basecall_models/barcoding/

# Copy the raw fast5s to the temporary scratch folder
cp -r ${rawFast5_DIR} ./rawFast5

#Move fast5s from children folders to the parent folder
find ./rawFast5 -type f -name "*.fast5" | xargs mv -t ./rawFast5

#Create a txt file containing the absolute filename of all raw fast5s
find ./rawFast5 -type f -name "*.fast5" > rawFast5s_list.txt

#Get total number of fast5s and half it
tot_fast5s=$(find ./rawFast5 -type f -name "*.fast5" | wc -l)
let half_1=${tot_fast5s}/2
let half_2=${tot_fast5s}-${half_1}

# Get a list for each half
head -${half_1} rawFast5s_list.txt > rawFast5s_half1.txt
tail -${half_2} rawFast5s_list.txt > rawFast5s_half2.txt

# Create folders and move the fast5s
mkdir -p ./rawFast5/1 ./rawFast5/2
xargs mv -t ./rawFast5/1 < rawFast5s_half1.txt
xargs mv -t ./rawFast5/2 < rawFast5s_half2.txt

conda deactivate