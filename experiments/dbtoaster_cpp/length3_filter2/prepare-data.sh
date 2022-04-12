#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

experiment_mode=$1
data_path=$2

CONFIG_FILES=("${PARENT_PARENT_PATH}/experiment.cfg")

mkdir -p "${SCRIPT_PATH}/${experiment_mode}"

if [[ "${experiment_mode}" = "perf" ]]; then
    window_factor1=$(prop 'length3.filter2.window.factor1')
    window_factor2=$(prop 'length3.filter2.window.factor2')

    java -jar "${PARENT_PARENT_PATH}/data-tools/target/data-tools.jar" "-c2" "dbtoastercpp" "${data_path}/data.csv" "${SCRIPT_PATH}/perf" "${window_factor1}" "data1.csv" "${window_factor2}" "data2.csv"
    cp "${SCRIPT_PATH}/perf/data1.csv" "${SCRIPT_PATH}/perf/data3.csv"

    # replace filename in query template to absolute path
    rm -f "${SCRIPT_PATH}/perf/query.sql"
    cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/perf/query.sql"
    sed -i "s#data1.csv#${SCRIPT_PATH}/perf/data1.csv#g" "${SCRIPT_PATH}/perf/query.sql"
    sed -i "s#data2.csv#${SCRIPT_PATH}/perf/data2.csv#g" "${SCRIPT_PATH}/perf/query.sql"
    sed -i "s#data3.csv#${SCRIPT_PATH}/perf/data3.csv#g" "${SCRIPT_PATH}/perf/query.sql"
fi

chmod -Rf g=u "${SCRIPT_PATH}/perf/"