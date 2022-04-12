#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

CONFIG_FILES=("${PARENT_PATH}/tools.cfg" "${PARENT_PARENT_PATH}/experiment.cfg")

log_file="${PARENT_PATH}/log/produce-data-length3_filter.log"

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

# produce data for perf test
graph_input_path=$(prop 'graph.input.path')
graph_output_path="${SCRIPT_PATH}/${experiment_name}/perf/data.csv"

cp "${graph_input_path}" "${graph_output_path}"
chmod -Rf g=rw "${SCRIPT_PATH}/perf/"