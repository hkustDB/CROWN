#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

system_name=$1
experiment_name=$2

CONFIG_FILES=("${SCRIPT_PATH}/tools.cfg")

log_file="${SCRIPT_PATH}/log/validate-result-${system_name}-${experiment_name}.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

producer_home=$(prop 'data.tools.home')
java -jar ${producer_home}/target/data-tools.jar -v "$@" >> ${log_file} 2>&1
