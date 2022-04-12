#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")

batch=$(prop 'batch.size.num')
echo "batch size = ${batch}"