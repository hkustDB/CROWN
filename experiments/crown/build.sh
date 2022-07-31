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

crown_home=$(prop 'crown.code.home')
cd ${crown_home}

rm -rf "${crown_home}/target/"

mvn "clean" >> ${log_file} 2>&1

mvn "compile" "-DskipTests=true" >> ${log_file} 2>&1
assert "crown compile failed."

mvn "package" "-DskipTests=true" >> ${log_file} 2>&1
assert "crown package failed."
chmod -Rf g=u "${crown_home}/target/"