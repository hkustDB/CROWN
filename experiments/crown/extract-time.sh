#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/perf.cfg" "${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

crown_home=$(prop 'crown.code.home')
crown_mode=$(prop 'crown.experiment.mode')

if [[ "${crown_mode}" = 'minicluster' ]]; then
    # run in MiniCluster, extract time from log
    execution_log="${SCRIPT_PATH}/log/execute-${experiment_name}.log"
    exec_time=$(grep "StartTime" "${execution_log}" | grep "EndTime" | grep "AccumulateTime" | awk '{print $13}' | sort -n | tail -n1)
    exec_time_in_sec=$(echo "scale=2; ${exec_time}/1000000000" | bc)
    echo "${exec_time_in_sec}"
else
    # run in ScalaTest, extract time from test report
    report_path="${crown_home}/target/surefire-reports/TestSuite.txt"
    total=$(grep "+ Execution time" ${report_path} | awk '{print $4}')
    echo "${total}"
fi
