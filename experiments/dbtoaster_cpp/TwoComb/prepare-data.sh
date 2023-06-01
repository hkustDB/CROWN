#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")


rm -f "${SCRIPT_PATH}/query.sql"
cp -f "${SCRIPT_PATH}/query.sql.template" "${SCRIPT_PATH}/query.sql"