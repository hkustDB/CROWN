#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PLOT_PATH=$(dirname "${SCRIPT_PATH}")
ROOT_PATH=$(dirname "${PLOT_PATH}")

function load {
    tsk_file=$1

    if [[ ! -f ${tsk_file} ]]; then
        echo "-1"
    else
        content=$(cat "${tsk_file}")
        if [[ -n ${content} ]]; then
            echo "${content}"
        else
            echo "-1"
        fi
    fi
}

function append {
    f2=$2
    f3=$3
    f4=$4
    f5=$5
    target_file=$6

    v1=$1
    v2=$(load "${f2}")
    v3=$(load "${f3}")
    v4=$(load "${f4}")
    v5=$(load "${f5}")

    echo "${v1} ${v2} ${v3} ${v4} ${v5}" >> "${target_file}"
}

target_file_path="${ROOT_PATH}/log/result"
target_file="${target_file_path}/figure8.dat"
mkdir -p "${target_file_path}"
rm -f "${target_file}"
touch "${target_file}"

# parallelism
result_path_q1="${ROOT_PATH}/log/result/parallelism"
append "1" "${result_path_q1}/task1.txt" "${result_path_q1}/task7.txt" "${result_path_q1}/task13.txt" "${result_path_q1}/task19.txt" "${target_file}"
append "2" "${result_path_q1}/task2.txt" "${result_path_q1}/task8.txt" "${result_path_q1}/task14.txt" "${result_path_q1}/task20.txt" "${target_file}"
append "3" "${result_path_q1}/task3.txt" "${result_path_q1}/task9.txt" "${result_path_q1}/task15.txt" "${result_path_q1}/task21.txt" "${target_file}"
append "4" "${result_path_q1}/task4.txt" "${result_path_q1}/task10.txt" "${result_path_q1}/task16.txt" "${result_path_q1}/task22.txt" "${target_file}"
append "5" "${result_path_q1}/task5.txt" "${result_path_q1}/task11.txt" "${result_path_q1}/task17.txt" "${result_path_q1}/task23.txt" "${target_file}"
append "6" "${result_path_q1}/task6.txt" "${result_path_q1}/task12.txt" "${result_path_q1}/task18.txt" "${result_path_q1}/task24.txt" "${target_file}"

cd "${ROOT_PATH}"
mkdir -p "log/figure"
gnuplot -c "plot/figure8/plot.plt"