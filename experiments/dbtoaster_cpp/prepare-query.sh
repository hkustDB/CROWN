#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

log_file="${SCRIPT_PATH}/log/prepare-query-${experiment_name}.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

dbtoaster_home=$(prop 'dbtoaster.backend.home')
cd ${dbtoaster_home}

modes=('perf' 'func')
for mode in ${modes[@]}; do
    query_file="${SCRIPT_PATH}/${experiment_name}/${mode}/query.sql"

    output_path="${SCRIPT_PATH}/${experiment_name}/${mode}"
    mkdir -p ${output_path}

    output_file="${output_path}/query.hpp"

    # substitute filter condition in sql template
    filter_value=$(prop 'filter.condition.value' '-1')
    sed -i "s/\${filter\.condition\.value}/${filter_value}/g" "${query_file}"

    sbt "toast -l cpp -O3 --del -o ${output_file} ${query_file}" >> ${log_file} 2>&1
    assert "dbtoaster compile query failed."

    exe_file="${output_path}/query.exe"
    g++-11 -O3 -std=c++14 -I "${dbtoaster_home}/ddbtoaster/release/lib/dbt_c++/lib/" -I "${dbtoaster_home}/ddbtoaster/release/lib/dbt_c++/driver/" "${dbtoaster_home}/ddbtoaster/release/lib/dbt_c++/driver/main.cpp" -include ${output_file} -o ${exe_file} >> ${log_file} 2>&1
done

chmod -Rf g=u "${SCRIPT_PATH}/${experiment_name}"