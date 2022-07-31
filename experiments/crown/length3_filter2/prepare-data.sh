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
    window_factor1=$(prop 'length3.filter2.window.factor1')
    window_factor2=$(prop 'length3.filter2.window.factor2')

    java -jar "${PARENT_PARENT_PATH}/data-tools/target/data-tools.jar" "-c2" "crown" "${data_path}/data.csv" "${SCRIPT_PATH}/data.csv" "${window_factor1}" "G1,G3" "${window_factor2}" "G2"
    target_path="${SCRIPT_PATH}/perf.cfg"
    rm -f ${target_path}
    echo "path.to.data.csv=${SCRIPT_PATH}/data.csv" > ${target_path}
fi