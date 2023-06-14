#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_PATH}/common.sh"

log_file="${SCRIPT_PATH}/log/run_fig7.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

function run_task_fig7 {
    spec_file=$1
    current_task=$2
    spec_result_path=$3
    task_result_file="${spec_result_path}/task${current_task}.txt"
    rm -f ${task_result_file}
    touch ${task_result_file}
    CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
    system=$(prop "task${current_task}.system.name")
    experiment=$(prop "task${current_task}.experiment.name")
    execution_time='-1'

    log_file_temp="${SCRIPT_PATH}/data/log/produce-data-length3.log"
    mkdir -p "${SCRIPT_PATH}/data/log"
    chmod -f g=rwx "${SCRIPT_PATH}/data/log"
    rm -f ${log_file_temp}
    touch ${log_file_temp}
    chmod -f g=rw ${log_file_temp}
    tools_home=$(prop 'data.tools.home')
    window_factor=$(prop "task${current_task}.winbig.factor")
    graphdir=$(prop 'graph.input.path')
    graphname=$(prop "task${current_task}.input.file")
    graph_input_path="${graphdir}/${graphname}.txt"
    mkdir -p "${SCRIPT_PATH}/data/length3"
    graph_raw_path="${SCRIPT_PATH}/data/length3/data.raw"
    graph_output_path="${SCRIPT_PATH}/data/length3/data.csv"
    cp -f ${graph_input_path} "${graph_raw_path}"
    java -jar "${tools_home}/target/data-tools.jar" "-c3" "crown" "${graph_raw_path}" "${graph_output_path}" "G1,G3" "${window_factor}" "G2" >> ${log_file_temp} 2>&1
    chmod -Rf g=rw "${SCRIPT_PATH}/data/length3/"

    mkdir -p "${SCRIPT_PATH}/crown/length3"
    target_path="${SCRIPT_PATH}/crown/length3/perf.cfg"
    rm -f ${target_path}
    touch ${target_path}
    chmod -f g=rw ${target_path}
    data_path=${SCRIPT_PATH}/data/length3
    files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
    for file in ${files[@]}
    do
        filename=$(basename ${file})
        echo "path.to.${filename}=${data_path}/${filename}" >> "${target_path}"
    done

    CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/crown/length3/perf.cfg" "${SCRIPT_PATH}/experiment.cfg")
    mkdir -p "${SCRIPT_PATH}/crown/log"
    execute_log="${SCRIPT_PATH}/crown/log/execute-length3.log"
    rm -f ${execute_log}
    touch ${execute_log}
    crown_home=$(prop 'crown.code.home')
    crown_mode=$(prop 'crown.experiment.mode')
    input_file=$(prop 'path.to.data.csv')
    delta_enable=$(prop 'crown.delta.enum.enable' 'false')
    full_enable=$(prop 'crown.full.enum.enable' 'true')
    filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
    cd "${crown_home}"
    if [[ ${crown_mode} = 'minicluster' ]]; then
        crown_class_name=$(prop "task${current_task}.minicluster.entry.class")
        input_path=$(dirname "${input_file}")
        input_file_name=$(basename "${input_file}")
        parallelism=$(prop 'crown.minicluster.parallelism')
        if [[ ${filter_value} -ge 0 ]]; then
            timeout -s SIGKILL 14400s taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" "--n" "${filter_value}" >> ${execute_log} 2>&1
        else
            timeout -s SIGKILL 14400s taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" >> ${execute_log} 2>&1
        fi
        extracted_time=$(grep "StartTime" "${execute_log}" | grep "EndTime" | grep "AccumulateTime" | awk '{print $13}' | sort -n | tail -n1)
        if [[ -n ${extracted_time} ]]; then
            current_execution_time=${extracted_time}
            execution_time=$(echo "scale=2; ${current_execution_time}/1000000000" | bc)
        fi
    fi
    cd ${SCRIPT_PATH}
    echo ${execution_time} >> ${task_result_file}
}

function run_spec_fig7 {
    spec_file=$1
    echo "run_spec_fig7 ${spec_file}" >> ${log_file}
    CONFIG_FILES=(${spec_file})
    task_count=$(prop 'spec.tasks.count')
    echo "task_count ${task_count}" >> ${log_file}
    query_name=$(prop 'spec.query.name')
    spec_result_path="${SCRIPT_PATH}/log/result/${query_name}"
    mkdir -p "${spec_result_path}"
    current_task=1
    while [[ ${current_task} -le ${task_count} ]]
    do
        echo "run_task_fig7 ${current_task}" >> ${log_file}
        run_task_fig7 ${spec_file} ${current_task} ${spec_result_path}
        current_task=$(($current_task+1))
    done
}

run_spec_fig7 "${SCRIPT_PATH}/specs/enclosureness.spec"