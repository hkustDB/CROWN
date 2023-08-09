#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_PATH}/common.sh"

log_file="${SCRIPT_PATH}/log/execute.log"

mkdir -p "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}


function execute_task {
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
        if [ ${experiment} == "TwoComb" ] || [ ${experiment} == "snb4_window" ] || [ ${experiment} == "dumbbell" ]; then
            return 1
        fi
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        execute_log="${SCRIPT_PATH}/dbtoaster/log/execute-${experiment}.log"
        execution_time_log="${SCRIPT_PATH}/dbtoaster/log/execution-time.log"
        mkdir -p "${SCRIPT_PATH}/dbtoaster/log"
        rm -f ${execute_log}
        touch ${execute_log}
        rm -f ${execution_time_log}
        touch ${execution_time_log}
        enum_points_list=$(cat "${SCRIPT_PATH}/dbtoaster/${experiment}/enum-points-perf.txt")
        timeout_time=$(prop 'common.experiment.timeout')
        timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -jar "${SCRIPT_PATH}/dbtoaster/target/experiments-dbtoaster.jar" ${experiment} ${execution_time_log} -b$(prop 'batch.size.num') -d$(prop "task${current_task}.dataset.name") --cfg-file /spark.config.${experiment}.perf "-ep${enum_points_list}" --no-output >> ${execute_log} 2>&1    

        extracted_time=$(grep "Total time (running + hsync):" "${SCRIPT_PATH}/dbtoaster/log/execute-${experiment}.log" | awk '{print $7}')
        if [[ -n ${extracted_time} ]]; then
            current_execution_time=${extracted_time}
            execution_time=$(echo "scale=2; x=(${current_execution_time}/1000);  if(x<1){\"0\"};  x" | bc)
        fi

    elif [[ "${system}" == "dbtoaster_cpp" ]]; then
        CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
        execute_log="${SCRIPT_PATH}/dbtoaster_cpp/log/execute-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/dbtoaster_cpp/log"
        rm -f ${execute_log}
        touch ${execute_log}
        timeout_time=$(prop 'common.experiment.timeout')
        timeout -s SIGKILL "${timeout_time}" taskset -c "8" "${SCRIPT_PATH}/dbtoaster_cpp/${experiment}/query.exe" -r 1 >> ${execute_log} 2>&1

        extracted_time=$(tail "${SCRIPT_PATH}/dbtoaster_cpp/log/execute-${experiment}.log" | grep "Execution time" | awk '{print $9}')
        if [[ -n ${extracted_time} ]]; then
            current_execution_time=${extracted_time}
            execution_time=$(echo "scale=2; x=(${current_execution_time}/1000);  if(x<1){\"0\"};  x" | bc)
        fi
        
    elif [[ "${system}" == "flink" ]]; then
        CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
        execute_log="${SCRIPT_PATH}/flink/log/execute-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/flink/log"
        rm -f ${execute_log}
        touch ${execute_log}
        touch "${SCRIPT_PATH}/flink/log/execution-time.log"
        timeout_time=$(prop 'common.experiment.timeout')
        timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/flink/log/execution-time.log -jar "${SCRIPT_PATH}/flink/target/experiments-flink-jar-with-dependencies.jar" "${experiment}" >> ${execute_log} 2>&1

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

    elif [[ "${system}" == "trill" ]]; then
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        execute_log="${SCRIPT_PATH}/trill/log/execute-${experiment}.log"
        execution_time_log="${SCRIPT_PATH}/trill/log/execution-time.log"
        mkdir -p "${SCRIPT_PATH}/trill/log"
        rm -f ${execute_log}
        touch ${execute_log}
        rm -f ${execution_time_log}
        touch ${execution_time_log}
        cd "${SCRIPT_PATH}/trill"
        with_output=$(prop 'write.result.to.file' 'false')
        timeout_time=$(prop 'common.experiment.timeout')
        timeout -s SIGKILL "${timeout_time}" taskset -c "8" dotnet "${SCRIPT_PATH}/trill/bin/Debug/net5.0/experiments-trill.dll" "${experiment}" "${execution_time_log}" $(prop 'periodic.punctuation.policy.time') $(prop "task${current_task}.graph.inputsize") $(prop "task${current_task}.filter.condition.value" '-1') "withOutput=${with_output}" >> ${execute_log} 2>&1
        cd ${SCRIPT_PATH}

        extracted_time=$(echo $(cat "${SCRIPT_PATH}/trill/log/execution-time.log"))
        if [[ -n ${extracted_time} ]]; then
            execution_time=${extracted_time}
        fi

    elif [[ "${system}" == "crown" ]]; then
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/crown/${experiment}/perf.cfg" "${SCRIPT_PATH}/experiment.cfg")
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
            parallelism=$(prop 'crown.minicluster.parallelism')
            if [[ ${filter_value} -ge 0 ]]; then
                timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" "--n" "${filter_value}" >> ${execute_log} 2>&1
            else
                timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" >> ${execute_log} 2>&1
            fi
            
            # run in MiniCluster, extract time from log
            extracted_time=$(grep "StartTime" "${execute_log}" | grep "EndTime" | grep "AccumulateTime" | awk '{print $13}' | sort -n | tail -n1)
            if [[ -n ${extracted_time} ]]; then
                current_execution_time=${extracted_time}
                execution_time=$(echo "scale=2; ${current_execution_time}/1000000000" | bc)
            fi

        else
            crown_test_name=$(prop "task${current_task}.test.entry.class")
            timeout -s SIGKILL "${timeout_time}" mvn "test" "-Dsuites=${crown_test_name}" "-Dconfig=srcFile=${input_file},deltaEnumEnable=${delta_enable},fullEnumEnable=${full_enable}" >> ${execute_log} 2>&1
            
            # run in ScalaTest, extract time from test report
            report_path="${crown_home}/target/surefire-reports/TestSuite.txt"
            extracted_time=$(grep "+ Execution time" ${report_path} | awk '{print $4}')
            if [[ -n ${extracted_time} ]]; then
                execution_time=${extracted_time}
            fi
        fi
        cd ${SCRIPT_PATH}

    elif [[ "${system}" == "crown_delta" ]]; then
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/crown/${experiment}/perf.cfg" "${SCRIPT_PATH}/experiment.cfg")
        mkdir -p "${SCRIPT_PATH}/crown/log"
        execute_log="${SCRIPT_PATH}/crown/log/execute-${experiment}.log"
        rm -f ${execute_log}
        touch ${execute_log}
        crown_home=$(prop 'crown.code.home')
        crown_mode=$(prop 'crown.experiment.mode')
        input_file=$(prop 'path.to.data.csv')
        delta_enable='true'
        full_enable='false'
        filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
        timeout_time=$(prop 'common.experiment.timeout')
        cd "${crown_home}"
        if [[ ${crown_mode} = 'minicluster' ]]; then
            crown_class_name=$(prop "task${current_task}.minicluster.entry.class")
            input_path=$(dirname "${input_file}")
            input_file_name=$(basename "${input_file}")
            parallelism=$(prop 'crown.minicluster.parallelism')
            if [[ ${filter_value} -ge 0 ]]; then
                timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" "--n" "${filter_value}" >> ${execute_log} 2>&1
            else
                timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" >> ${execute_log} 2>&1
            fi

            # run in MiniCluster, extract time from log
            extracted_time=$(grep "StartTime" "${execute_log}" | grep "EndTime" | grep "AccumulateTime" | awk '{print $13}' | sort -n | tail -n1)
            if [[ -n ${extracted_time} ]]; then
                current_execution_time=${extracted_time}
                execution_time=$(echo "scale=2; ${current_execution_time}/1000000000" | bc)
            fi
        else
            crown_test_name=$(prop "task${current_task}.test.entry.class")
            timeout -s SIGKILL "${timeout_time}" mvn "test" "-Dsuites=${crown_test_name}" "-Dconfig=srcFile=${input_file},deltaEnumEnable=${delta_enable},fullEnumEnable=${full_enable}" >> ${execute_log} 2>&1

            # run in ScalaTest, extract time from test report
            extracted_time=$(grep "+ Execution time" ${report_path} | awk '{print $4}')
            if [[ -n ${extracted_time} ]]; then
                execution_time=${extracted_time}
            fi
        fi
        cd ${SCRIPT_PATH}

    else
        echo "error for execute experiment ${experiment} for system ${system}" >> ${log_file}
    fi

    echo ${execution_time} >> ${task_result_file}
}

function execute_spec {
    spec_file=$1
    echo "execute_spec ${spec_file}" >> ${log_file}
    CONFIG_FILES=(${spec_file})
    query_name=$(prop 'spec.query.name')
    spec_result_path="${SCRIPT_PATH}/log/result/${query_name}"
    mkdir -p "${spec_result_path}"
    task_count=$(prop 'spec.tasks.count')
    echo "task_count ${task_count}" >> ${log_file}
    current_task=1
    while [[ ${current_task} -le ${task_count} ]]
    do
        echo "execute_task ${current_task}" >> ${log_file}
        execute_task ${spec_file} ${current_task} ${spec_result_path}
        current_task=$(($current_task+1))
    done
}

# execute for figure10
execute_spec "${SCRIPT_PATH}/specs/full_join_queries.spec"
execute_spec "${SCRIPT_PATH}/specs/join_project_queries.spec"
execute_spec "${SCRIPT_PATH}/specs/agg_queries.spec"

