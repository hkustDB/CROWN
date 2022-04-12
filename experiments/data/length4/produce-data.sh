#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

CONFIG_FILES=("${PARENT_PATH}/tools.cfg" "${PARENT_PARENT_PATH}/experiment.cfg")

log_file="${PARENT_PATH}/log/produce-data-length4.log"

mkdir -p "${PARENT_PATH}/log"
chmod -f g=rwx "${PARENT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

mkdir -p "${SCRIPT_PATH}/perf"
chmod -f g=rwx "${SCRIPT_PATH}/perf"
mkdir -p "${SCRIPT_PATH}/func"
chmod -f g=rwx "${SCRIPT_PATH}/func"

tools_home=$(prop 'data.tools.home')
window_factor=$(prop 'experiment.window.factor')

# produce data for func test
java -jar ${tools_home}/target/data-tools.jar -p "length4" "${SCRIPT_PATH}/${experiment_name}" "func" >> ${log_file} 2>&1
func_raw_path="${SCRIPT_PATH}/${experiment_name}/func/data.raw"
func_output_path="${SCRIPT_PATH}/${experiment_name}/func/data.csv"
# window the raw data to produce data for other systems
java -jar "${tools_home}/target/data-tools.jar" -ft "${func_raw_path}" "${func_output_path}" >> ${log_file} 2>&1
chmod -Rf g=rw "${SCRIPT_PATH}/func/"

# produce data for perf test
graph_input_path=$(prop 'graph.input.path')
graph_raw_path="${SCRIPT_PATH}/${experiment_name}/perf/data.raw"
graph_output_path="${SCRIPT_PATH}/${experiment_name}/perf/data.csv"
# copy raw data for flink
cp -f ${graph_input_path} "${graph_raw_path}"
# window the raw data to produce data for other systems
java -jar "${tools_home}/target/data-tools.jar" -w "${graph_raw_path}" "${graph_output_path}" "${window_factor}" >> ${log_file} 2>&1
chmod -Rf g=rw "${SCRIPT_PATH}/perf/"