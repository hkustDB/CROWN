#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

ms=$(tail "${SCRIPT_PATH}/log/execute-${experiment_name}.log" | grep "Execution time" | awk '{print $9}')
echo "scale=2; x=(${ms}/1000);  if(x<1){\"0\"};  x" | bc
