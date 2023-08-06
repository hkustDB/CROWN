#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_PATH}/common.sh"

log_file="${SCRIPT_PATH}/log/run_fig9.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

spec_result_path="${SCRIPT_PATH}/log/result/latency"
mkdir -p "${spec_result_path}"
trill_result_file="${spec_result_path}/fig9_trill_result.txt"
rm -f ${trill_result_file}
touch ${trill_result_file}
crown_result_file="${spec_result_path}/fig9_crown_result.txt"
rm -f ${crown_result_file}
touch ${crown_result_file}

CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
log_file_temp="${SCRIPT_PATH}/data/log/produce-data-length4_latency.log"
mkdir -p "${SCRIPT_PATH}/data/log"
chmod -f g=rwx "${SCRIPT_PATH}/data/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=rw ${log_file_temp}
tools_home=$(prop 'data.tools.home')
window_factor=$(prop 'experiment.window.factor')
graphdir=$(prop 'graph.input.path')
graph_input_path="${graphdir}/bitcoin.txt"
mkdir -p "${SCRIPT_PATH}/data/length4_latency"
graph_raw_path="${SCRIPT_PATH}/data/length4_latency/data.raw"
graph_output_path="${SCRIPT_PATH}/data/length4_latency/data.csv"
cp -f ${graph_input_path} "${graph_raw_path}"
java -jar "${tools_home}/target/data-tools.jar" -w "${graph_raw_path}" "${graph_output_path}" "${window_factor}" >> ${log_file_temp} 2>&1
chmod -Rf g=rw "${SCRIPT_PATH}/data/length4_latency/"

data_path=${SCRIPT_PATH}/data/length4_latency

# build trill
echo "trill" >> ${log_file}
key="length4_latency.perf.path"
pattern="^\\s*<add\\s\\s*key\\s*=\\s*\"${key}\"\\s\\s*value\\s*=\\s*\".*\"\\s*\/>\\s*$"
app_config="${SCRIPT_PATH}/trill/app.config"
if [[ ! -f ${app_config} ]]; then
    touch ${app_config}
    chmod -f g=rw ${app_config}
    echo "<configuration>" >> ${app_config}
    echo "<appSettings>" >> ${app_config}
    echo "</appSettings>" >> ${app_config}
    echo "</configuration>" >> ${app_config}
fi
value="${SCRIPT_PATH}/trill/length4_latency"
files=$(find ${data_path} -maxdepth 1 -type f -name '*.csv')
for file in ${files[@]}; do
    name=$(basename "${file}")
    bash "${SCRIPT_PATH}/data/convert-data.sh" "trill" "${data_path}/${name}" "${SCRIPT_PATH}/trill/length4_latency/${name}"
done
grep -q ${pattern} ${app_config} \
&& sed -i "s#${pattern}#<add key=\"${key}\" value=\"${value}\"/>#g" ${app_config} \
|| sed -i "/<appSettings>/a<add key=\"${key}\" value=\"${value}\"\/>" ${app_config}
dotnet build "${SCRIPT_PATH}/trill/experiments-trill.csproj" "/property:GenerateFullPaths=true" "/consoleloggerparameters:NoSummary" >> ${log_file_temp} 2>&1


# build crown
echo "crown" >> ${log_file}
log_file_temp="${SCRIPT_PATH}/crown/log/prepare-data-length4_latency.log"
mkdir -p "${SCRIPT_PATH}/crown/log"
chmod -f g=rwx "${SCRIPT_PATH}/crown/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=rw ${log_file_temp}
target_path="${SCRIPT_PATH}/crown/length4_latency/perf.cfg"
rm -f ${target_path}
touch ${target_path}
chmod -f g=rw ${target_path}
files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
for file in ${files[@]}
do
    filename=$(basename ${file})
    echo "path.to.${filename}=${data_path}/${filename}" >> "${target_path}"
done

# execute trill
CONFIG_FILES=("${SCRIPT_PATH}/trill/length4_latency/common.cfg" "${SCRIPT_PATH}/experiment.cfg")
execute_log="${SCRIPT_PATH}/trill/log/execute-length4_latency.log"
execution_time_log="${SCRIPT_PATH}/trill/log/execution-time.log"
mkdir -p "${SCRIPT_PATH}/trill/log"
rm -f ${execute_log}
touch ${execute_log}
rm -f ${execution_time_log}
touch ${execution_time_log}
cd "${SCRIPT_PATH}/trill"
with_output=$(prop 'write.result.to.file' 'false')
timeout_time=$(prop 'common.experiment.timeout')
timeout -s SIGKILL "${timeout_time}" taskset -c "8" dotnet "${SCRIPT_PATH}/trill/bin/Debug/net5.0/experiments-trill.dll" "length4_latency" "${execution_time_log}" $(prop 'periodic.punctuation.policy.time') $(prop 'graph.input.size') $(prop 'filter.condition.value' '-1') "withOutput=${with_output}" >> ${execute_log} 2>&1
cd ${SCRIPT_PATH}

avg_latancy=$(grep "avg latancy =" "${SCRIPT_PATH}/trill/log/execute-length4_latency.log" | awk '{print $4}')
echo ${avg_latancy} >> ${trill_result_file}
sed -i 's/ /\n/g' ${trill_result_file}

# excute crown
CONFIG_FILES=("${SCRIPT_PATH}/crown/length4_latency/common.cfg" "${SCRIPT_PATH}/crown/length4_latency/perf.cfg" "${SCRIPT_PATH}/experiment.cfg")
mkdir -p "${SCRIPT_PATH}/crown/log"
execute_log="${SCRIPT_PATH}/crown/log/execute-length4_latency.log"
rm -f ${execute_log}
touch ${execute_log}
crown_home=$(prop 'crown.code.home')
crown_mode=$(prop 'crown.experiment.mode')
input_file=$(prop 'path.to.data.csv')
delta_enable='true'
full_enable='false'
filter_value=$(prop 'filter.condition.value' '-1')
timeout_time=$(prop 'common.experiment.timeout')
cd "${crown_home}"
if [[ ${crown_mode} = 'minicluster' ]]; then
    crown_class_name=$(prop 'minicluster.entry.class')
    input_path=$(dirname "${input_file}")
    input_file_name=$(basename "${input_file}")
    parallelism=$(prop 'crown.minicluster.parallelism')
    if [[ ${filter_value} -ge 0 ]]; then
        timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" "--n" "${filter_value}" >> ${execute_log} 2>&1
    else
        timeout -s SIGKILL "${timeout_time}" taskset -c "8" java -Xms128g -Xmx128g -DexecutionTimeLogPath=${SCRIPT_PATH}/crown/log/execution-time.log -cp "target/CROWN-1.0-SNAPSHOT.jar" ${crown_class_name} "--path" "${input_path}" "--graph" "${input_file_name}" "--parallelism" "${parallelism}" "--deltaEnumEnable" "${delta_enable}" "--fullEnumEnable" "${full_enable}" >> ${execute_log} 2>&1
    fi

    fileLatency="${input_path}/L4.csv" # latency record file
    lines_per_chunk=2000000 
    awk -F 'lat: ' -v lines_per_chunk="$lines_per_chunk" -v crown_result_file="$crown_result_file" '
    {
        sum += $2
        count++
        if (count % lines_per_chunk == 0) {
            average = sum / count
            printf "%.2f\n", average >> crown_result_file
            fflush()
        }
    }
    END {
        if (count > 0) {
            average = sum / count
            printf "%.2f\n", average >> crown_result_file
            fflush()
        }
    }
    ' "$fileLatency"
fi

cd ${SCRIPT_PATH}
