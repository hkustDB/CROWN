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
    # f1=$1
    # f2=$2
    # f3=$3
    # f4=$4
    # f5=$5
    # target_file=$6

    # v1=$(load "${f1}")
    # v2=$(load "${f2}")
    # v3=$(load "${f3}")
    # v4=$(load "${f4}")
    # v5=$(load "${f5}")

    # echo "${v1} ${v2} ${v3} ${v4} ${v5}" >> "${target_file}"
}

target_file_path="${ROOT_PATH}/log/result"
target_file="${target_file_path}/figure9.dat"
mkdir -p "${target_file_path}"
rm -f "${target_file}"
touch "${target_file}"

# latency
result_path_q1="${ROOT_PATH}/log/result/latency"
append "XXX" "${target_file}"

cd "${ROOT_PATH}"
mkdir -p "log/figure"
gnuplot -c "plot/figure9/plot.plt"