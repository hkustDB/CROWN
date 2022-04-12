#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"
CONFIG_FILES=("${SCRIPT_PATH}/tools.cfg")

log_file="${SCRIPT_PATH}/log/prepare-tools.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

producer_home=$(prop 'data.tools.home')
cd ${producer_home}

rm -rf "${producer_home}/target/"
rm -rf "${producer_home}/project/target/"
rm -rf "${producer_home}/project/project/"

sbt clean >> ${log_file} 2>&1
sbt compile >> ${log_file} 2>&1
assert "data tools compile failed."

sbt assembly >> ${log_file} 2>&1
assert "data tools assembly failed."
chmod -Rf g=u "${producer_home}/target"
chmod -Rf g=u "${producer_home}/project"