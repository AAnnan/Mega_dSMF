#! /bin/bash

#
# /!\ To launch in the terminal with bash
# varSettings.sh needs to be in the same folder

source ./varSettings.sh

work_DIR=$(pwd)
echo "work_DIR="${work_DIR} >> varSettings.sh
mkdir output

##Input Guppy's latest VERSION:

read -p 'Input Guppy version (ie: 5.0.11), check it here: community.nanoporetech.com/downloads/guppy/release_notes :' GUPPY_VERSION

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
conda create --name ${condaEnv} --yes

#Activate conda env
source ~/.bashrc
source ${CONDA_ACTIVATE} ${condaEnv}

#Install fetchchromsizes
conda install -c bioconda ucsc-fetchchromsizes --yes

#Install wigToBigWig
conda install -c bioconda ucsc-wigtobigwig --yes

#Install Samtools
conda install -c bioconda samtools --yes

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

source ${work_DIR}/varSettings.sh
# Copy Guppy's barcoding models into Rerio's folder
cp ${GUPPY_DIR}/../data/barcoding/* ./rerio/basecall_models/barcoding/

echo "Done with the simple Mega_dSMF pipeline installation"
echo "Launch the scripts in numerical order with sbatch."
