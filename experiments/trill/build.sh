#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"
source "${SCRIPT_PATH}/env.sh"

flag_skip_test=$1

log_file="${SCRIPT_PATH}/log/build.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=rwx "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=rw ${log_file}

cd ${SCRIPT_PATH}
rm -rf "${SCRIPT_PATH}/bin"
rm -rf "${SCRIPT_PATH}/obj"

dotnet build "${SCRIPT_PATH}/experiments-trill.csproj" "/property:GenerateFullPaths=true" "/consoleloggerparameters:NoSummary" >> ${log_file} 2>&1
assert "trill executable build failed."

chmod -Rf g=u "${SCRIPT_PATH}/bin"
chmod -Rf g=u "${SCRIPT_PATH}/obj"

if [[ ${flag_skip_test} -ne 1 ]]; then
    dotnet test "${SCRIPT_PATH}/experiments-trill.csproj" >> ${log_file} 2>&1
    assert "trill func test failed."
fi

chmod -Rf g=u "${SCRIPT_PATH}/bin"
chmod -Rf g=u "${SCRIPT_PATH}/obj"