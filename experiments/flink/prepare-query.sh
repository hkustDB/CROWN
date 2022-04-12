#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

mkdir -p ${SCRIPT_PATH}/src/main/resources/${experiment_name}
chmod -f g=rwx ${SCRIPT_PATH}/src/main/resources/${experiment_name}
cp -f ${SCRIPT_PATH}/${experiment_name}/*.sql ${SCRIPT_PATH}/src/main/resources/${experiment_name}/
chmod -f g=rw ${SCRIPT_PATH}/src/main/resources/${experiment_name}/*.sql