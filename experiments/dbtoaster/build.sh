#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

flag_skip_test=$1

log_file="${SCRIPT_PATH}/log/build.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

cd ${SCRIPT_PATH}

rm -rf "${SCRIPT_PATH}/target"
rm -rf "${SCRIPT_PATH}/project/target"
rm -rf "${SCRIPT_PATH}/project/project"

sbt clean >> ${log_file} 2>&1
sbt compile >> ${log_file} 2>&1
assert "dbtoaster executable compile failed."

if [[ ${flag_skip_test} -eq 0 ]]; then 
    tests=$(ls "${SCRIPT_PATH}/src/test/scala/experiments/dbtoaster")
    for test in ${tests[@]}; do
        sbt "testOnly experiments.dbtoaster.${test}.FuncTest" >> ${log_file} 2>&1
        assert "FuncTest ${test} failed."
    done
fi

sbt assembly >> ${log_file} 2>&1
assert "dbtoaster executable assembly failed."

chmod -Rf g=u "${SCRIPT_PATH}/target"
chmod -Rf g=u "${SCRIPT_PATH}/project"