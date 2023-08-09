#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_PATH}/common.sh"

log_file="${SCRIPT_PATH}/log/run_fig8.log"
mkdir -p "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}

function execute_task_fig8 {
    spec_file=$1
    current_task=$2
    spec_result_path=$3
    task_result_file="${spec_result_path}/task${current_task}.txt"
    rm -f ${task_result_file}
    touch ${task_result_file}
    CONFIG_FILES=("${spec_file}")
    system=$(prop "task${current_task}.system.name")
    experiment=$(prop "task${current_task}.experiment.name")
    execution_time='-1'

    if [[ "${system}" == "dbtoaster" ]]; then
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        executor_cores=$(prop "task${current_task}.executor.cores")

        config="${SCRIPT_PATH}/dbtoaster/src/main/resources/spark.config.${experiment}.perf"
        rm -f ${config}
        echo "spark.master.url=$(prop "task${current_task}.master.url")" >> $config
        echo "spark.partitions.num=$(prop "task${current_task}.partitions.num")" >> $config
        echo "spark.driver.memory=$(prop 'spark.driver.memory')" >> $config
        echo "spark.executor.memory=$(prop "task${current_task}.executor.memory")" >> $config
        echo "spark.executor.cores=$(prop 'spark.executor.cores')" >> $config
        echo "spark.home.dir=$(prop 'spark.home.dir')" >> $config
        echo "spark.kryoserializer.buffer.max=2047m" >> $config
        echo "dist.input.path=$(prop 'hdfs.root.path')/$(prop 'hdfs.dist.dir')/" >> $config
        chmod -f g=u ${config}

        execute_log="${SCRIPT_PATH}/dbtoaster/log/execute-${experiment}.log"
        execution_time_log="${SCRIPT_PATH}/dbtoaster/log/execution-time.log"
        mkdir -p "${SCRIPT_PATH}/dbtoaster/log"
        rm -f ${execute_log}
        touch ${execute_log}
        rm -f ${execution_time_log}
        touch ${execution_time_log}
        enum_points_list=$(cat "${SCRIPT_PATH}/dbtoaster/${experiment}/enum-points-perf.txt")
        timeout_time=$(prop 'common.experiment.timeout')
        timeout -s SIGKILL "${timeout_time}" taskset -c "${executor_cores}" java -Xms500g -Xmx500g -jar "${SCRIPT_PATH}/dbtoaster/target/experiments-dbtoaster.jar" ${experiment} ${execution_time_log} -b$(prop 'batch.size.num') -d$(prop "task${current_task}.dataset.name") --cfg-file /spark.config.${experiment}.perf "-ep${enum_points_list}" --no-output >> ${execute_log} 2>&1    

        extracted_time=$(grep "Execution Time:" "${SCRIPT_PATH}/dbtoaster/log/execute-${experiment}.log" | awk '{print $3}')
        if [[ -n ${extracted_time} ]]; then
            execution_time=${extracted_time}
        else
            extracted_total_time=$(grep "Total time (running + hsync):" "${SCRIPT_PATH}/dbtoaster/log/execute-${experiment}.log" | awk '{print $7}')
            if [[ -n ${extracted_total_time} ]]; then
                current_execution_time=${extracted_total_time}
                execution_time=$(echo "scale=2; x=(${current_execution_time}/1000);  if(x<1){\"0\"};  x" | bc)
            fi 
        fi
    elif [[ "${system}" == "flink" ]]; then
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        target_path="${SCRIPT_PATH}/flink/src/main/resources/${experiment}"
        rm -f "${target_path}/perf.cfg"
        touch "${target_path}/perf.cfg"
        chmod -f g=rw "${target_path}/perf.cfg"
        parallelism=$(prop "task${current_task}.perf.parallelism")
        echo "flink.job.parallelism=${parallelism}" >> "${target_path}/perf.cfg"

        data_path=${SCRIPT_PATH}/data/${experiment}
        total_lines=$(find ${data_path} -maxdepth 1 -type f -name "*.raw" | xargs wc -l | tail -n1 | awk '{print $1}')
        window_factor=$(prop 'experiment.window.factor')
        half_window_size=$(bc <<< "${total_lines}*${window_factor}/2")
        window_size=$(bc <<< "${half_window_size}*2")
        files=$(find ${data_path} -maxdepth 1 -type f -name '*.raw')
        for file in ${files[@]}; do
            name=$(basename "${file}")
            echo "path.to.${name}=${SCRIPT_PATH}/flink/${experiment}/${name}" >> "${target_path}/perf.cfg"
            echo "hop.window.step=${half_window_size}" >> "${target_path}/perf.cfg"
            step_day=$(bc <<< "${half_window_size} / 86400")
            step_hour=$(bc <<< "(${half_window_size} - ${step_day} * 86400) / 3600")
            step_minute=$(bc <<< "(${half_window_size} - ${step_day} * 86400 - ${step_hour} * 3600) / 60")
            step_second=$(bc <<< "(${half_window_size} - ${step_day} * 86400 - ${step_hour} * 3600 - ${step_minute} * 60)")
            echo "hop.window.step.day=${step_day}" >> "${target_path}/perf.cfg"
            echo "hop.window.step.hour=${step_hour}" >> "${target_path}/perf.cfg"
            echo "hop.window.step.minute=${step_minute}" >> "${target_path}/perf.cfg"
            echo "hop.window.step.second=${step_second}" >> "${target_path}/perf.cfg"
            echo "hop.window.size=${window_size}" >> "${target_path}/perf.cfg"
            size_day=$(bc <<< "${window_size} / 86400")
            size_hour=$(bc <<< "(${window_size} - ${size_day} * 86400) / 3600")
            size_minute=$(bc <<< "(${window_size} - ${size_day} * 86400 - ${size_hour} * 3600) / 60")
            size_second=$(bc <<< "(${window_size} - ${size_day} * 86400 - ${size_hour} * 3600 - ${size_minute} * 60)")
            echo "hop.window.size.day=${size_day}" >> "${target_path}/perf.cfg"
            echo "hop.window.size.hour=${size_hour}" >> "${target_path}/perf.cfg"
            echo "hop.window.size.minute=${size_minute}" >> "${target_path}/perf.cfg"
            echo "hop.window.size.second=${size_second}" >> "${target_path}/perf.cfg"
        done
    
        filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
        echo "filter.condition.value=${filter_value}" >> "${target_path}/perf.cfg"

        executor_cores=$(prop "task${current_task}.executor.cores")
        execute_log="${SCRIPT_PATH}/flink/log/execute-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/flink/log"
        rm -f ${execute_log}
        touch ${execute_log}
        touch "${SCRIPT_PATH}/flink/log/execution-time.log"
        timeout_time=$(prop 'common.experiment.timeout')
        timeout -s SIGKILL "${timeout_time}" taskset -c "${executor_cores}" java -Xms500g -Xmx500g -DexecutionTimeLogPath=${SCRIPT_PATH}/flink/log/execution-time.log -jar "${SCRIPT_PATH}/flink/target/experiments-flink-jar-with-dependencies.jar" "${experiment}" >> ${execute_log} 2>&1

        startime=$(cat "${SCRIPT_PATH}/flink/log/execution-time.log" | awk '/Job .* (.*) switched from state CREATED to RUNNING./{print $1; exit}')
        if [[ -n ${startime} ]]; then
            endtime=$(cat "${SCRIPT_PATH}/flink/log/execution-time.log" | awk '/Job .* (.*) switched from state RUNNING to FINISHED./{print $1; exit}')
            if [[ -n ${endtime} ]]; then
                start_seconds=$(date --date="${startime}" +%s)
                end_seconds=$(date --date="${endtime}" +%s)
                extracted_time=$((end_seconds-start_seconds))
                # handle the corner case where the job ends on the next day
                if [[ ${extracted_time} -lt 0 ]]; then
                    extracted_time=$((${extracted_time} + 86400))
                fi
                execution_time=${extracted_time}
            fi
        fi
    elif [[ "${system}" == "crown" ]]; then
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/crown/${experiment}/perf.cfg" "${SCRIPT_PATH}/experiment.cfg")
        executor_cores=$(prop "task${current_task}.executor.cores")
        mkdir -p "${SCRIPT_PATH}/crown/log"
        execute_log="${SCRIPT_PATH}/crown/log/execute-${experiment}.log"
        rm -f ${execute_log}
        touch ${execute_log}
        crown_home=$(prop 'crown.code.home')
        crown_mode=$(prop 'crown.experiment.mode')
        input_file=$(prop 'path.to.data.csv')
        delta_enable='false'
        full_enable='true'
        filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
        timeout_time=$(prop 'common.experiment.timeout')
        cd "${crown_home}"
        if [[ ${crown_mode} = 'minicluster' ]]; then
            crown_class_name=$(prop "task${current_task}.minicluster.entry.class")
            input_path=$(dirname "${input_file}")
            input_file_name=$(basename "${input_file}")
            parallelism=$(prop "task${current_task}.minicluster.parallelism")
            if [[ ${filter_value} -ge 0 ]]; then
                timeout -s SIGKILL "${timeout_time}" taskset -c "${executor_cores}" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" "--n" "${filter_value}" >> ${execute_log} 2>&1
            else
                timeout -s SIGKILL "${timeout_time}" taskset -c "${executor_cores}" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" >> ${execute_log} 2>&1
            fi
            # run in MiniCluster, extract time from log
            extracted_time=$(grep "StartTime" "${execute_log}" | grep "EndTime" | grep "AccumulateTime" | awk '{print $13}' | sort -n | tail -n1)
            if [[ -n ${extracted_time} ]]; then
                current_execution_time=${extracted_time}
                execution_time=$(echo "scale=2; ${current_execution_time}/1000000000" | bc)
            fi
        fi
        cd ${SCRIPT_PATH}
    else
        echo "error for execute experiment ${experiment} for system ${system}" >> ${log_file}
    fi

    echo ${execution_time} >> ${task_result_file}
}

function execute_spec_fig8 {
    spec_file=$1
    echo "execute_spec_fig8 ${spec_file}" >> ${log_file}
    CONFIG_FILES=(${spec_file})
    query_name=$(prop 'spec.query.name')
    spec_result_path="${SCRIPT_PATH}/log/result/${query_name}"
    mkdir -p "${spec_result_path}"
    task_count=$(prop 'spec.tasks.count')
    echo "task_count ${task_count}" >> ${log_file}
    current_task=1
    while [[ ${current_task} -le ${task_count} ]]
    do
        echo "execute_task_fig8 ${current_task}" >> ${log_file}
        execute_task_fig8 ${spec_file} ${current_task} ${spec_result_path}
        current_task=$(($current_task+1))
    done
}


# build for figure8
# build_spec_fig8 "${SCRIPT_PATH}/specs/parallelism.spec"

# execute for figure8
execute_spec_fig8 "${SCRIPT_PATH}/specs/parallelism.spec"
