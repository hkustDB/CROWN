#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
available_cores=$2

log_file="${SCRIPT_PATH}/log/execute-${experiment_name}.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

touch "${SCRIPT_PATH}/log/execution-time.log"
chmod -f g=rw "${SCRIPT_PATH}/log/execution-time.log"

timeout -s SIGKILL 14400s taskset -c "${available_cores}" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/log/execution-time.log -jar "${SCRIPT_PATH}/target/experiments-flink-jar-with-dependencies.jar" "${experiment_name}" >> ${log_file} 2>&1