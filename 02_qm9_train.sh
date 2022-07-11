#!/bin/bash -l



WORKDIR=/hpcgpfs01/work/cfn/mcarbone/XAS-NNE
N_ENSEMBLES=30
PRINT_EVERY_EPOCH=50
N_GPU=1


run_random_qm9()
{

    if [ "$1" == "execute" ]; then
        executable="sbatch"
    else
        executable="echo"
    fi
    declare -a paths=(
        "XANES-220710-ACSF-O-RANDOM-SPLITS-PCA-decomp-maxcol-21"
        "XANES-220710-ACSF-N-RANDOM-SPLITS-PCA-decomp-maxcol-25"
        "XANES-220710-ACSF-C-RANDOM-SPLITS-PCA-decomp-maxcol-23"
    )

    declare -a downsample_values=(0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1)

    for path in "${paths[@]}"; do
        for downsample_prop in "${downsample_values[@]}"; do
            "$executable" .02_qm9_train.sbatch.sh \
                --data-path "$WORKDIR"/"$path".pkl \
                --ensemble-name Ensembles/"$path"/"$downsample_prop" \
                --downsample-prop "$downsample_prop" \
                --print-every-epoch "$PRINT_EVERY_EPOCH" \
                --n-gpu "$N_GPU" \
                -n "$N_ENSEMBLES"
        done
    done
}

run_random_qm9 "$1"
