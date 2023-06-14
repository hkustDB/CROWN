#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

system_name=$1
src_file=$2
dst_file=$3

CONFIG_FILES=("${PARENT_PATH}/experiment.cfg")

log_file="${SCRIPT_PATH}/log/convert-data-${system_name}.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

producer_home=$(prop 'data.tools.home')
# pass all the args to data-tools, since some convertors may relies on extra args other than src_file and dst_file
java -jar ${producer_home}/target/data-tools.jar -c "$@" >> ${log_file} 2>&1
chmod -f g=rw ${dst_file}