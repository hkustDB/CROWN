#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")

log_file="${SCRIPT_PATH}/log/prepare-system.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

dbtoaster_home=$(prop 'dbtoaster.backend.home')
cd ${dbtoaster_home}

rm -rf "${dbtoaster_home}/target"
rm -rf "${dbtoaster_home}/project/target"
rm -rf "${dbtoaster_home}/project/project"

sbt clean >> ${log_file}
sbt compile >> ${log_file}
assert "dbtoaster compile failed."

release_path="${dbtoaster_home}/ddbtoaster/release"
sbt release >> ${log_file}
assert "dbtoaster release failed."

rm -rf "${SCRIPT_PATH}/lib"
mkdir -p "${SCRIPT_PATH}/lib"
cp ${release_path}/lib/dbt_scala/dbtoaster*.jar ${SCRIPT_PATH}/lib/
chmod -Rf g=u "${release_path}"
chmod -Rf g=u "${SCRIPT_PATH}/lib/"

chmod -Rf g=u "${dbtoaster_home}/target"
chmod -Rf g=u "${dbtoaster_home}/project"