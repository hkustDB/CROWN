#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PLOT_PATH=$(dirname "${SCRIPT_PATH}")
ROOT_PATH=$(dirname "${PLOT_PATH}")

target_file_path="${ROOT_PATH}/log/result"
target_file="${target_file_path}/figure9.dat"
mkdir -p "${target_file_path}"
rm -f "${target_file}"
touch "${target_file}"

result_path="${ROOT_PATH}/log/result/latency"
paste -d' ' <(seq 1 29) <(awk '{print $1}' "${result_path}/fig9_trill_result.txt") <(awk '{print $1}' "${result_path}/fig9_crown_result.txt") > "$target_file"
cd "${ROOT_PATH}"
mkdir -p "log/figure"
gnuplot -c "plot/figure9/plot.plt"