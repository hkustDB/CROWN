#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
experiment_mode=$2
data_path=$3

CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")

if [[ -f "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" ]]; then
    # dispatch to prepare-data.sh under specific experiment
    bash "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" ${experiment_mode} ${data_path}
else
    # default prepare data behaviour
    log_file="${SCRIPT_PATH}/log/prepare-data-${experiment_name}-${experiment_mode}.log"

    mkdir -p "${SCRIPT_PATH}/log"
    chmod -f g=rwx "${SCRIPT_PATH}/log"
    rm -f ${log_file}
    touch ${log_file}
    chmod -f g=rw ${log_file}

    target_path="${SCRIPT_PATH}/${experiment_name}/${experiment_mode}.cfg"
    rm -f ${target_path}
    touch ${target_path}
    chmod -f g=rw ${target_path}

    files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
    for file in ${files[@]}
    do
        filename=$(basename ${file})
        echo "path.to.${filename}=${data_path}/${filename}" >> "${target_path}"
    done
fi
