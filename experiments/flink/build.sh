#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

flag_skip_test=$1

log_file="${SCRIPT_PATH}/log/build.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

cd ${SCRIPT_PATH}

rm -rf "${SCRIPT_PATH}/target/"

mvn "clean" >> ${log_file} 2>&1
mvn "compile" "-DskipTests" >> ${log_file} 2>&1
assert "flink executable compile failed."

if [[ ${flag_skip_test} -eq 0 ]]; then
    mvn "test" >> ${log_file} 2>&1
    assert "flink FuncTest failed."
fi

mvn "package" "-DskipTests" >> ${log_file} 2>&1
assert "flink executable package failed."
chmod -Rf g=u "${SCRIPT_PATH}/target/"