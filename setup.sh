#! /bin/bash

source ./varSettings.sh

work_DIR=$(pwd)
echo "work_DIR="${work_DIR} >> varSettings.sh

##Input Guppy's latest VERSION:

read -p 'Input newest Guppy version (ie: 4.0.14): ' GUPPY_VERSION

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
echo "SOFTWARE_DIR="${SOFTWARE_DIR} >> varSettings.sh

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

#Get fetchChromSizes
wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/fetchChromSizes

#Get Chrom sizes
bash fetchChromSizes ce11 > ce11.chrom.sizes

#Install wigToBigWig 
conda install -c bioconda ucsc-wigtobigwig --yes

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

echo "GUPPY_DIR="${SOFTWARE_DIR}/ont-guppy/bin >> varSettings.sh

#Install Megalodon
pip3 install Megalodon
pip3 install git+https://github.com/nanoporetech/megalodon@guppy_client

echo "Everything looks ready for your Megalodon run"