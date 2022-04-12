#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
available_cores=$2

CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")

execute_log="${SCRIPT_PATH}/log/execute-${experiment_name}.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${execute_log}
touch ${execute_log}
chmod -f g=u ${execute_log}

timeout -s SIGKILL 14400s taskset -c "${available_cores}" "${SCRIPT_PATH}/${experiment_name}/perf/query.exe" -r 1 >> ${execute_log} 2>&1