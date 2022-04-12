#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")
PARENT_PARENT_PATH=$(dirname "${PARENT_PATH}")

source "${PARENT_PARENT_PATH}/common.sh"

experiment_mode=$1
data_path=$2

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_mode}.cfg" "${SCRIPT_PATH}/common.cfg" "${PARENT_PATH}/experiment.cfg" "${PARENT_PARENT_PATH}/experiment.cfg")

mkdir -p "${SCRIPT_PATH}/${experiment_mode}"

if [[ "${experiment_mode}" = "perf" ]]; then
    batch_size=$(prop 'batch.size.num')
    window_factor1=$(prop 'length3.filter2.window.factor1')
    window_factor2=$(prop 'length3.filter2.window.factor2')

    mkdir -p "/tmp/dbtoaster_tmp"
    java -jar "${PARENT_PARENT_PATH}/data-tools/target/data-tools.jar" "-c2" "dbtoaster" "${data_path}/data.csv" "${SCRIPT_PATH}" "${window_factor1}" "data1.csv" "${window_factor2}" "data2.csv" "${batch_size}" "2"

    root=$(prop 'hdfs.root.path')
    dist=$(prop 'hdfs.dist.dir')
    dataset=$(prop 'dataset.name')
    hdfs_path=$(prop 'hdfs.cmd.path')
    ${hdfs_path} dfs -mkdir -p ${root}/${dist}/${dataset} > /dev/null 2>&1
    assert "HDFS create dataset directory failed."
    ${hdfs_path} dfs -rm -r ${root}/${dist}/${dataset}/checkpoint > /dev/null 2>&1

    ${hdfs_path} dfs -put -f "${SCRIPT_PATH}/data1.csv" "${root}/${dist}/${dataset}/data1.csv" > /dev/null 2>&1
    ${hdfs_path} dfs -put -f "${SCRIPT_PATH}/data2.csv" "${root}/${dist}/${dataset}/data2.csv" > /dev/null 2>&1
    assert "HDFS put file failed."
fi