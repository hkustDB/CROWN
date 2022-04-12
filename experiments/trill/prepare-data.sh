#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
experiment_mode=$2
data_path=$3

mkdir -p "${SCRIPT_PATH}/${experiment_name}/${experiment_mode}"
chmod -f g=rwx "${SCRIPT_PATH}/${experiment_name}/${experiment_mode}"

key="${experiment_name}.${experiment_mode}.path"
pattern="^\\s*<add\\s\\s*key\\s*=\\s*\"${key}\"\\s\\s*value\\s*=\\s*\".*\"\\s*\/>\\s*$"
app_config="${SCRIPT_PATH}/app.config"

if [[ ! -f ${app_config} ]]; then
    touch ${app_config}
    chmod -f g=rw ${app_config}
    echo "<configuration>" >> ${app_config}
    echo "<appSettings>" >> ${app_config}
    echo "</appSettings>" >> ${app_config}
    echo "</configuration>" >> ${app_config}
fi

if [[ -f "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" ]]; then
    bash "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" "${experiment_mode}" "${data_path}"
else
    if [[ ${experiment_name} = snb* ]]; then
        # snb experiments use pre-constructed input file directly
        value="${data_path}"
    else
        value="${SCRIPT_PATH}/${experiment_name}/${experiment_mode}"
        files=$(find ${data_path} -maxdepth 1 -type f -name '*.csv')
        for file in ${files[@]}; do
            name=$(basename "${file}")
            bash "${PARENT_PATH}/data/convert-data.sh" "trill" "${data_path}/${name}" "${SCRIPT_PATH}/${experiment_name}/${experiment_mode}/${name}"
        done
    fi

    grep -q ${pattern} ${app_config} \
    && sed -i "s#${pattern}#<add key=\"${key}\" value=\"${value}\"/>#g" ${app_config} \
    || sed -i "/<appSettings>/a<add key=\"${key}\" value=\"${value}\"\/>" ${app_config}
fi
