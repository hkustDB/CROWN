#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")


mkdir -p "${SCRIPT_PATH}/perf"
rm -f "${SCRIPT_PATH}/perf/query.sql"
cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/perf/query.sql"

mkdir -p "${SCRIPT_PATH}/func"
rm -f "${SCRIPT_PATH}/func/query.sql"
cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/func/query.sql"