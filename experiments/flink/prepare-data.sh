#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1
experiment_mode=$2
data_path=$3

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg" "${PARENT_PATH}/experiment.cfg")

if [[ "${experiment_mode}" == "perf" ]]; then
    target_path="${SCRIPT_PATH}/src/main/resources/${experiment_name}"
    mkdir -p "${target_path}"
    chmod -f g=rwx "${SCRIPT_PATH}/src/main/resources/${experiment_name}"
    rm -f "${target_path}/${experiment_mode}.cfg"
    touch "${target_path}/${experiment_mode}.cfg"
    chmod -f g=rw "${target_path}/${experiment_mode}.cfg"
    parallelism=$(prop 'flink.perf.parallelism')
    echo "flink.job.parallelism=${parallelism}" >> "${target_path}/${experiment_mode}.cfg"
elif [[ "${experiment_mode}" == "func" ]]; then
    target_path="${SCRIPT_PATH}/src/test/resources/${experiment_name}"
    mkdir -p "${target_path}"
    chmod -f g=rwx "${SCRIPT_PATH}/src/test/resources/${experiment_name}"
    rm -f "${target_path}/${experiment_mode}.cfg"
    touch "${target_path}/${experiment_mode}.cfg"
    chmod -f g=rw "${target_path}/${experiment_mode}.cfg"
    parallelism=$(prop 'flink.func.parallelism')
    echo "flink.job.parallelism=${parallelism}" >> "${target_path}/${experiment_mode}.cfg"
else
    err "unknown experiment mode: ${experiment_mode}"
    exit 1
fi

if [[ ${experiment_name} = snb* ]]; then
    # snb experiment, just set the flink.xxx.xxx.csv config to the path of csv file
    files=$(find ${data_path} -maxdepth 1 -type f -name 'flink.*.csv')
    for file in ${files[@]}; do
        name=$(basename "${file}")
        echo "path.to.${name}=${file}" >> "${target_path}/${experiment_mode}.cfg"
    done
else
    # non snb experiment, construct flink readable data.raw and calculate the window size and step
    total_lines=$(find ${data_path} -maxdepth 1 -type f -name "*.raw" | xargs wc -l | tail -n1 | awk '{print $1}')
    window_factor=$(prop 'experiment.window.factor')
    # calculate the half_window_size first, so that window_size is always double of half_window_size
    # if we do the opposite way, window_size may be a odd number and flink won't compile(size must be n times step).
    half_window_size=$(bc <<< "${total_lines}*${window_factor}/2")
    window_size=$(bc <<< "${half_window_size}*2")

    # create dir to store converted data
    mkdir -p "${SCRIPT_PATH}/${experiment_name}/${experiment_mode}"

    files=$(find ${data_path} -maxdepth 1 -type f -name '*.raw')
    for file in ${files[@]}; do
        name=$(basename "${file}")
        bash "${PARENT_PATH}/data/convert-data.sh" "flink" "${data_path}/${name}" "${SCRIPT_PATH}/${experiment_name}/${experiment_mode}/${name}"
        echo "path.to.${name}=${SCRIPT_PATH}/${experiment_name}/${experiment_mode}/${name}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.step=${half_window_size}" >> "${target_path}/${experiment_mode}.cfg"
        # convert ${hop.window.step} seconds to xx day xx hour xx minute xx second
        step_day=$(bc <<< "${half_window_size} / 86400")
        step_hour=$(bc <<< "(${half_window_size} - ${step_day} * 86400) / 3600")
        step_minute=$(bc <<< "(${half_window_size} - ${step_day} * 86400 - ${step_hour} * 3600) / 60")
        step_second=$(bc <<< "(${half_window_size} - ${step_day} * 86400 - ${step_hour} * 3600 - ${step_minute} * 60)")
        echo "hop.window.step.day=${step_day}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.step.hour=${step_hour}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.step.minute=${step_minute}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.step.second=${step_second}" >> "${target_path}/${experiment_mode}.cfg"

        echo "hop.window.size=${window_size}" >> "${target_path}/${experiment_mode}.cfg"
        size_day=$(bc <<< "${window_size} / 86400")
        size_hour=$(bc <<< "(${window_size} - ${size_day} * 86400) / 3600")
        size_minute=$(bc <<< "(${window_size} - ${size_day} * 86400 - ${size_hour} * 3600) / 60")
        size_second=$(bc <<< "(${window_size} - ${size_day} * 86400 - ${size_hour} * 3600 - ${size_minute} * 60)")
        echo "hop.window.size.day=${size_day}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.size.hour=${size_hour}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.size.minute=${size_minute}" >> "${target_path}/${experiment_mode}.cfg"
        echo "hop.window.size.second=${size_second}" >> "${target_path}/${experiment_mode}.cfg"
    done
fi

filter_value=$(prop 'filter.condition.value' '-1')
echo "filter.condition.value=${filter_value}" >> "${target_path}/${experiment_mode}.cfg"
