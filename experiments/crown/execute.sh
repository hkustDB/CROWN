#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
available_cores=$2

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/perf.cfg" "${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
execute_log="${SCRIPT_PATH}/log/execute-${experiment_name}.log"
rm -f ${execute_log}
touch ${execute_log}
chmod -f g=rw ${execute_log}

crown_home=$(prop 'crown.code.home')
crown_mode=$(prop 'crown.experiment.mode')
input_file=$(prop 'path.to.data.csv')
delta_enable=$(prop 'crown.delta.enum.enable' 'false')
full_enable=$(prop 'crown.full.enum.enable' 'true')

filter_value=$(prop 'filter.condition.value' '-1')

cd "${crown_home}"
if [[ ${crown_mode} = 'minicluster' ]]; then
    crown_class_name=$(prop "minicluster.entry.class")
    input_path=$(dirname "${input_file}")
    input_file_name=$(basename "${input_file}")
    parallelism=$(prop 'crown.minicluster.parallelism')

    # add --n ${filter_value} when filter_value >= 0
    if [[ ${filter_value} -ge 0 ]]; then
        timeout -s SIGKILL 14400s taskset -c "${available_cores}" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" "--n" "${filter_value}" >> ${execute_log} 2>&1
    else
        timeout -s SIGKILL 14400s taskset -c "${available_cores}" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" >> ${execute_log} 2>&1
    fi
else
    crown_test_name=$(prop "test.entry.class")
    timeout -s SIGKILL 14400s mvn "test" "-Dsuites=${crown_test_name}" "-Dconfig=srcFile=${input_file},deltaEnumEnable=${delta_enable},fullEnumEnable=${full_enable}" >> ${execute_log} 2>&1
fi