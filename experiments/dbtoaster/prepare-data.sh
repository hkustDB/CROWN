#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
experiment_mode=$2
data_path=$3

if [[ -f "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" ]]; then
    bash "${SCRIPT_PATH}/${experiment_name}/prepare-data.sh" ${experiment_mode} ${data_path}
else
    CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/${experiment_mode}.cfg" "${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

    log_file="${SCRIPT_PATH}/log/prepare-data-${experiment_name}-${experiment_mode}.log"

    mkdir -p "${SCRIPT_PATH}/log"
    chmod -f g=u "${SCRIPT_PATH}/log"
    rm -f ${log_file}
    touch ${log_file}
    chmod -f g=u ${log_file}

    root=$(prop 'hdfs.root.path')
    dist=$(prop 'hdfs.dist.dir')
    dataset=$(prop 'dataset.name')
    hdfs_path=$(prop 'hdfs.cmd.path')
    ${hdfs_path} dfs -mkdir -p ${root}/${dist}/${dataset} >> ${log_file} 2>&1
    assert "HDFS create dataset directory failed."
    ${hdfs_path} dfs -rm -r ${root}/${dist}/${dataset}/checkpoint >> ${log_file} 2>&1

    multiplier=$(prop 'line.count.multiplier' '1')
    batch_size=$(prop 'batch.size.num')

    if [[ ${experiment_name} = snb* ]]; then
        files=$(find "${data_path}" -maxdepth 1 -type f -name 'dbtoaster.*.csv')
        for file in ${files[@]}
        do
            filename=$(basename ${file})
            ${hdfs_path} dfs -put -f "${file}" ${root}/${dist}/${dataset}/${filename} >> ${log_file} 2>&1
            assert "HDFS put file failed."
        done
        cp "${data_path}/enum-points-perf.txt" "${SCRIPT_PATH}/${experiment_name}/enum-points-perf.txt"
    else
        files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
        for file in ${files[@]}
        do
            filename=$(basename ${file})
            bash "${PARENT_PATH}/data/convert-data.sh" "dbtoaster" "${file}" "/tmp/${filename}.dbtoaster.tmp" "${multiplier}" "${batch_size}" "${SCRIPT_PATH}/${experiment_name}/enum-points-${experiment_mode}.txt"
            ${hdfs_path} dfs -put -f /tmp/${filename}.dbtoaster.tmp ${root}/${dist}/${dataset}/${filename} >> ${log_file} 2>&1
            assert "HDFS put file failed."
            rm -f /tmp/${filename}.dbtoaster.tmp
        done
    fi
fi
