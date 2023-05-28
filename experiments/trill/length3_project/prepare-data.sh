#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

data_path=$1

key="length3_project.perf.path"
pattern="^\\s*<add\\s\\s*key\\s*=\\s*\"${key}\"\\s\\s*value\\s*=\\s*\".*\"\\s*\/>\\s*$"
app_config="${PARENT_PATH}/app.config"

target_path="${SCRIPT_PATH}/perf/data.csv"
rm -f ${target_path}
awk 'BEGIN{cnt=1}{printf "%s%s%s%s",cnt++,",",$1,ORS}' "${data_path}/data.raw" > "${target_path}"

value="${SCRIPT_PATH}/perf"

grep -q ${pattern} ${app_config} \
&& sed -i "s#${pattern}#<add key=\"${key}\" value=\"${value}\"/>#g" ${app_config} \
|| sed -i "/<appSettings>/a<add key=\"${key}\" value=\"${value}\"\/>" ${app_config}