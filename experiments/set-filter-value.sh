#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_PATH}/common.sh"

new_value=$1

log_file="${SCRIPT_PATH}/log/set-filter-value.log"

rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

cfg_files=$(find ${SCRIPT_PATH} -maxdepth 100 -type f -name '*.cfg')
for cfg_file in ${cfg_files[@]}; do
    echo "set filter.condition.value to ${new_value} in ${cfg_file}" >> ${log_file}
    sed -i "s/^filter\.condition\.value=.*$/filter\.condition\.value=${new_value}/g" "${cfg_file}"
done