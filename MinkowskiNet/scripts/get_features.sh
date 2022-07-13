#!/usr/bin/env bash

set -x
# Exit script when a command returns nonzero state
set -e

set -o pipefail

export OMP_NUM_THREADS=2
export PYTHONUNBUFFERED="True"
export CUDA_VISIBLE_DEVICES=$1
export EXPERIMENT=$2
export INPUT_FEAT=$3
export TIME=$(date +"%Y-%m-%d_%H-%M-%S")

export DATASET=${DATASET:-BuildingNetVoxelization0_01Dataset}
export MODEL=${MODEL:-Res16UNet34A}
export OPTIMIZER=${OPTIMIZER:-SGD}
export LR=${LR:-1e-1}
export BATCH_SIZE=${BATCH_SIZE:-32}
export SCHEDULER=${SCHEDULER:-ReduceLROnPlateau}
export MAX_ITER=${MAX_ITER:-60000}

export OUTPATH=./outputs/$DATASET/$MODEL/${OPTIMIZER}-l$LR-b$BATCH_SIZE-$SCHEDULER-i$MAX_ITER-$EXPERIMENT-$INPUT_FEAT/${TIME}_output_feat
export VERSION=$(git rev-parse HEAD)

# Save the experiment detail and dir to the common log file
mkdir -p $OUTPATH

LOG="$OUTPATH/$TIME.txt"

# put the arguments on the first line for easy resume
echo -e "
    --log_dir $OUTPATH \
    --dataset $DATASET \
    --model $MODEL \
    --lr $LR \
    --optimizer $OPTIMIZER \
    --scheduler $SCHEDULER \
    --input_feat $INPUT_FEAT \
    $4" >> $LOG
echo Logging output to "$LOG"
echo $(pwd) >> $LOG
echo "Version: " $VERSION >> $LOG
echo "Git diff" >> $LOG
echo "" >> $LOG
git diff | tee -a $LOG
echo "" >> $LOG
nvidia-smi | tee -a $LOG

time python -W ignore main.py \
    --log_dir $OUTPATH \
    --dataset $DATASET \
    --model $MODEL \
    --input_feat $INPUT_FEAT \
    $4 2>&1 | tee -a "$LOG"
