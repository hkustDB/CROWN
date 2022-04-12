#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment=$1

exec_time=$(grep "Execution Time:" "${SCRIPT_PATH}/log/execute-${experiment}.log" | awk '{print $3}')
echo ${exec_time}
