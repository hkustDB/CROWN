#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
available_cores=$2

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/perf.cfg" "${SCRIPT_PATH}/experiment.cfg")

execute_log="${SCRIPT_PATH}/log/execute-${experiment_name}.log"
execution_time_log="${SCRIPT_PATH}/log/execution-time.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${execute_log}
touch ${execute_log}
chmod -f g=u ${execute_log}
rm -f ${execution_time_log}
touch ${execution_time_log}
chmod -f g=u ${execution_time_log}

enum_points_list=$(cat "${SCRIPT_PATH}/${experiment_name}/enum-points-perf.txt")

timeout -s SIGKILL 14400s taskset -c "${available_cores}" java -Xms128g -Xmx128g -jar "${SCRIPT_PATH}/target/experiments-dbtoaster.jar" ${experiment_name} ${execution_time_log} -b$(prop 'batch.size.num') -d$(prop 'dataset.name') --cfg-file /spark.config.${experiment_name}.perf "-ep${enum_points_list}" --no-output >> ${execute_log} 2>&1