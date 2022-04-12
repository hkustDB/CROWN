#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
experiment_mode=$2
data_path=$3

bash "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" "${experiment_mode}" "${data_path}"