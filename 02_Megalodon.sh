#! /bin/bash

## Resource Allocation
#SBATCH --time=10-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=128G
#SBATCH –-cpus-per-task=8

## job metadata
#SBATCH --job-name="Megalodon"
#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail

## Should be run in the same folder as varSettings.sh
## .bashrc should include location of bin directory inside Guppy directory and export it as ${GUPPY_DIR}
## .bashrc should include location of conda activate script and export it as ${CONDA_ACTIVATE}

source ./varSettings.sh

source ${CONDA_ACTIVATE} ${condaEnv}

# Move to scratch temp experiment folder
cd /scratch/TMP_Megalodon_${expName}

# Compute settings: 1 GPU and 8 CPU cores per run
# Other useful option : --num-reads 5000 \ (for testing)

megalodon ${work_DIR}/output/final_multifast5s_${expName}/ \
        --guppy-server-path ${GUPPY_DIR}/guppy_basecall_server \
        --guppy-params "-d ./rerio/basecall_models/ --num_callers 5 --ipc_threads 6" \
        --guppy-config ${modelConfig}.cfg \
        --outputs ${outputs[@]} \
        --output-directory ./megalodon_results_${expName}/ \
        --reference $genomeFile \
        --mod-motif m GCG 1 --mod-motif m HCG 1 --mod-motif m GCH 1 \
        --write-mods-text \
        --mod-aggregate-method binary_threshold \
        --mod-binary-threshold ${k} \
        --mod-output-formats bedmethyl wiggle \
        --sort-mappings \
        --mod-map-emulate-bisulfite \
        --mod-map-base-conv C T --mod-map-base-conv m C \
        --devices 0 --processes 8

cd ./megalodon_results_${expName}

##Split DB by motif, important for downstream analysis
megalodon_extras modified_bases split_by_motif $genomeFile \
        --motif GCG 1 --motif HCG 1 --motif GCH 1 \
        --megalodon-directory ./ \
        --output-suffix ${expName}_splitMotif \
        --output-prefix ${expName}

cp -r ../megalodon_results_${expName} ${work_DIR}/output/.

conda deactivate