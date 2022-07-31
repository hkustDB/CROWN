#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

mode=$(prop 'crown.experiment.mode')
echo "mode = ${mode},"
if [[ ${mode} = 'minicluster' ]]; then
    class=$(prop 'minicluster.entry.class')
    echo "class = ${class},"
    parallelism=$(prop 'crown.minicluster.parallelism')
    echo "parallelism = ${parallelism}"
else
    class=$(prop 'test.entry.class')
    echo "class = ${class}"
fi