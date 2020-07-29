#! /bin/bash

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
SOFTWARE_DIR=${HOME}/software_MethylBC
mkdir -p ${SOFTWARE_DIR}
cd $SOFTWARE_DIR
echo "Installing software from Methylation_Calling in " ${SOFTWARE_DIR}
echo "export SOFTWARE_DIR=${HOME}/software_MethylBC" >> ~/.bashrc

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
conda create --name MethylBC

#Activate conda env
conda activate MethylBC

#Install pip within your conda env
conda install pip

#Install Samtools
conda install -c bioconda samtools

#Install tensorflow
pip3 install tensorflow-gpu==1.15 

#Install Deepbinner 
pip3 install git+https://github.com/rrwick/Deepbinner.git

#Install ont fast5 api
pip3 install ont-fast5-api

#Install Guppy
wget https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy_${GUPPY_VERSION}_linux64.tar.gz
tar -xzvf ont-guppy_${GUPPY_VERSION}_linux64.tar.gz

echo "export GUPPY_DIR=${SOFTWARE_DIR}/ont-guppy/bin" >> ~/.bashrc

#Install Megalodon
pip3 install Megalodon
pip3 install git+https://github.com/nanoporetech/megalodon@guppy_client
