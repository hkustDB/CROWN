#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

experiment_mode=$1
data_path=$2

mkdir -p "${SCRIPT_PATH}/${experiment_mode}"

files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
for file in ${files[@]}
do
    filename=$(basename ${file})
    raw_name=${filename%.csv}
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}1.csv"
    bash "${PARENT_PARENT_PATH}/data/convert-data.sh" "dbtoastercpp" "${file}" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}1.csv" "insertEnumRow"
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv"
    bash "${PARENT_PARENT_PATH}/data/convert-data.sh" "dbtoastercpp" "${file}" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv"
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}3.csv"
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}4.csv"
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}5.csv"
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}6.csv"
    rm -rf "${SCRIPT_PATH}/${experiment_mode}/${raw_name}7.csv"
    cp "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}3.csv"
    cp "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}4.csv"
    cp "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}5.csv"
    cp "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}6.csv"
    cp "${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv" "${SCRIPT_PATH}/${experiment_mode}/${raw_name}7.csv"


    # replace filename in query template to absolute path
    rm -f "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}1.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}1.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}2.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}2.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}3.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}3.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}4.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}4.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}5.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}5.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}6.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}6.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
    sed -i "s#${raw_name}7.csv#${SCRIPT_PATH}/${experiment_mode}/${raw_name}7.csv#g" "${SCRIPT_PATH}/${experiment_mode}/query.sql"
done

chmod -Rf g=u "${SCRIPT_PATH}/${experiment_mode}"