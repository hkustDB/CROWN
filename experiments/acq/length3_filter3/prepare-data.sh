#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

experiment_mode=$1
data_path=$2

CONFIG_FILES=("${PARENT_PATH}/experiment.cfg" "${PARENT_PARENT_PATH}/experiment.cfg")

if [[ "${experiment_mode}" = "perf" ]]; then
    window_factor=$(prop 'length3.filter3.window.factor')

    java -jar "${PARENT_PARENT_PATH}/data-tools/target/data-tools.jar" "-c3" "acq" "${data_path}/data.csv" "${SCRIPT_PATH}/data.csv" "G1,G3" "${window_factor}" "G2"
    target_path="${SCRIPT_PATH}/perf.cfg"
    rm -f ${target_path}
    echo "path.to.data.csv=${SCRIPT_PATH}/data.csv" > ${target_path}
fi