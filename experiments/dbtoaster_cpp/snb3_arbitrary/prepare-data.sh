#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

data_path=$1

# replace filename in query template to absolute path
rm -f "${SCRIPT_PATH}/query.sql"
cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/query.sql"

files=$(find "${data_path}" -maxdepth 1 -type f -name 'dbtoaster_cpp.*.csv')
for file in ${files[@]}
do
    filename=$(basename ${file})
    sed -i "s#${filename}#${file}#g" "${SCRIPT_PATH}/query.sql"
done

chmod -Rf g=u "${SCRIPT_PATH}"