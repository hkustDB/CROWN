#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")

log_file="${SCRIPT_PATH}/log/build.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

acq_home=$(prop 'acq.code.home')
cd ${acq_home}

rm -rf "${acq_home}/target/"

mvn "clean" >> ${log_file} 2>&1

mvn "compile" "-DskipTests=true" >> ${log_file} 2>&1
assert "acq compile failed."

mvn "package" "-DskipTests=true" >> ${log_file} 2>&1
assert "acq package failed."
chmod -Rf g=u "${acq_home}/target/"