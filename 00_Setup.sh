#! /bin/bash

#
# /!\ To launch in the terminal with bash
# varSettings.sh needs to be in the same folder

source ./varSettings.sh

work_DIR=$(pwd)
echo "work_DIR="${work_DIR} >> varSettings.sh
mkdir output

##Input Guppy's latest VERSION:

read -p 'Input Newest Guppy version (ie: 4.0.15), check it here: community.nanoporetech.com/downloads/guppy/release_notes :' GUPPY_VERSION

if [[ ! $GUPPY_VERSION =~ ^[0-9,.]*$ ]]
then
    echo "Invalid version number"
    exit
else
	echo "Guppy "${GUPPY_VERSION}" will be downloaded"
fi

##Create software directory
SOFTWARE_DIR=${work_DIR}/software
mkdir -p ${SOFTWARE_DIR}
cd $SOFTWARE_DIR
echo "Installing software in " ${SOFTWARE_DIR}
echo "SOFTWARE_DIR="${SOFTWARE_DIR} >> ../varSettings.sh

#Install conda (or not if already installed)
#Dealing with miniconda vs anaconda installations
CONDA_PACKAGE=`which conda`
if [ ! ${CONDA_PACKAGE} ]; 
then 
	echo "Installing miniconda in" ${SOFTWARE_DIR};
	wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
	source ./Miniconda3-latest-Linux-x86_64.sh
fi

echo "export CONDA_ACTIVATE=${CONDA_PACKAGE%conda}activate" >> ~/.bashrc

#Create Conda env
conda create --name ${condaEnv} python=3.7 --yes

#Activate conda env
source ~/.bashrc
source ${CONDA_ACTIVATE} ${condaEnv}

#Install fetchchromsizes
conda install -c bioconda ucsc-fetchchromsizes --yes

#Install wigToBigWig
conda install -c bioconda ucsc-wigtobigwig --yes

#Install pycoQC
conda install -c aleg pycoqc --yes

#Install Samtools
conda install -c bioconda samtools --yes

#Install tensorflow-gpu 1.14
conda install tensorflow-gpu==1.14 --yes

#Install Deepbinner 
pip3 install git+https://github.com/rrwick/Deepbinner.git

#Install Keras 2.3.1
pip3 install Keras==2.3.1

#Install ont fast5 api
pip3 install ont-fast5-api

#Install Guppy
wget https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy_${GUPPY_VERSION}_linux64.tar.gz
tar -xzvf ont-guppy_${GUPPY_VERSION}_linux64.tar.gz

echo "GUPPY_DIR="${SOFTWARE_DIR}/ont-guppy/bin >> ../varSettings.sh

#Install Megalodon
pip3 install Megalodon
pip3 install ont_pyguppy_client_lib==$GUPPY_VERSION

# Create and move to a temporary scratch folder
mkdir -p /scratch/TMP_Megalodon_${expName}
cd /scratch/TMP_Megalodon_${expName}

### Get Rerio's research model from GitHub (if it doesn't exist already)
if [[ ! -f ./rerio/basecall_models/${modelConfig}.cfg ]]
then
	echo "Installing Rerio's modbases all context research model"
    git clone https://github.com/nanoporetech/rerio
	python rerio/download_model.py rerio/basecall_models/${modelConfig}
fi
# Copy Guppy's barcoding models into Rerio's folder
cp ${GUPPY_DIR}/../data/barcoding/* ./rerio/basecall_models/barcoding/

if [ "${two_pass}" = "yes" ]; then
	echo "Preparation of raw Fast5s before 2-pass demultiplexing"
	# Copy the raw fast5s to the temporary scratch folder
	mkdir -p /scratch/TMP_Megalodon_${expName}/rawFast5
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
fi

echo "Done"