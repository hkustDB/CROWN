#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"
source "${SCRIPT_PATH}/env.sh"

experiment_name=$1
available_cores=$2

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

log_file="${SCRIPT_PATH}/log/execute-${experiment_name}.log"
execution_time_log="${SCRIPT_PATH}/log/execution-time.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}
rm -f ${execution_time_log}
touch ${execution_time_log}
chmod -f g=rw ${execution_time_log}

cd "${SCRIPT_PATH}"
with_output=$(prop 'write.result.to.file' 'false')

timeout -s SIGKILL 14400s taskset -c "${available_cores}" dotnet "${SCRIPT_PATH}/bin/Debug/net5.0/experiments-trill.dll" "${experiment_name}" "${execution_time_log}" $(prop 'periodic.punctuation.policy.time') $(prop 'filter.condition.value' '-1') "withOutput=${with_output}" >> ${log_file} 2>&1