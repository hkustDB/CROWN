#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

data_path=$1

files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
for file in ${files[@]}
do
    filename=$(basename ${file})
    raw_name=${filename%.csv}
    rm -rf "${SCRIPT_PATH}/${raw_name}1.csv"
    bash "${PARENT_PARENT_PATH}/data/convert-data.sh" "dbtoastercpp" "${file}" "${SCRIPT_PATH}/${raw_name}1.csv" "insertEnumRow"
    rm -rf "${SCRIPT_PATH}/${raw_name}2.csv"
    bash "${PARENT_PARENT_PATH}/data/convert-data.sh" "dbtoastercpp" "${file}" "${SCRIPT_PATH}/${raw_name}2.csv"

    # replace filename in query template to absolute path
    rm -f "${SCRIPT_PATH}/query.sql"
    cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/query.sql"
    sed -i "s#${raw_name}1.csv#${SCRIPT_PATH}/${raw_name}1.csv#g" "${SCRIPT_PATH}/query.sql"
    sed -i "s#${raw_name}2.csv#${SCRIPT_PATH}/${raw_name}2.csv#g" "${SCRIPT_PATH}/query.sql"
done

chmod -Rf g=u "${SCRIPT_PATH}"