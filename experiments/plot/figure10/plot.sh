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
    crown_file=$1
    flink_file=$2
    dbtoaster_cpp_file=$3
    dbtoaster_file=$4
    crown_delta_file=$5
    trill_file=$6
    target_file=$7

    crown_value=$(load "${crown_file}")
    flink_value=$(load "${flink_file}")
    dbtoaster_cpp_value=$(load "${dbtoaster_cpp_file}")
    dbtoaster_value=$(load "${dbtoaster_file}")
    crown_delta_value=$(load "${crown_delta_file}")
    trill_value=$(load "${trill_file}")

    echo "${crown_value} ${flink_value} ${dbtoaster_cpp_value} ${dbtoaster_value} ${crown_delta_value} ${trill_value}" >> "${target_file}"
}

target_file_path="${ROOT_PATH}/log/result"
target_file="${target_file_path}/figure10.dat"
mkdir -p "${target_file_path}"
rm -f "${target_file}"
touch "${target_file}"

# full_join
result_path_q1="${ROOT_PATH}/log/result/fulljoin"
# Q1-3-Hop
append "${result_path_q1}/task1.txt" "${result_path_q1}/task2.txt" "${result_path_q1}/task3.txt" "${result_path_q1}/task4.txt" "${result_path_q1}/task5.txt" "${result_path_q1}/task6.txt" "${target_file}"

# Q1-4-Hop
append "${result_path_q1}/task7.txt" "${result_path_q1}/task8.txt" "${result_path_q1}/task9.txt" "${result_path_q1}/task10.txt" "${result_path_q1}/task11.txt" "${result_path_q1}/task12.txt" "${target_file}"

# Q1-2-Comb
append "${result_path_q1}/task13.txt" "${result_path_q1}/task14.txt" "${result_path_q1}/task15.txt" "${result_path_q1}/task16.txt" "${result_path_q1}/task17.txt" "${result_path_q1}/task18.txt" "${target_file}"

# Q1-SNB1
append "${result_path_q1}/task19.txt" "${result_path_q1}/task20.txt" "${result_path_q1}/task21.txt" "${result_path_q1}/task22.txt" "${result_path_q1}/task23.txt" "${result_path_q1}/task24.txt" "${target_file}"

# Q1-SNB2
append "${result_path_q1}/task25.txt" "${result_path_q1}/task26.txt" "${result_path_q1}/task27.txt" "${result_path_q1}/task28.txt" "${result_path_q1}/task29.txt" "${result_path_q1}/task30.txt" "${target_file}"

# Q1-SNB3
append "${result_path_q1}/task31.txt" "${result_path_q1}/task32.txt" "${result_path_q1}/task33.txt" "${result_path_q1}/task34.txt" "${result_path_q1}/task35.txt" "${result_path_q1}/task36.txt" "${target_file}"

# Q1-dumbbell
append "${result_path_q1}/task37.txt" "${result_path_q1}/task38.txt" "${result_path_q1}/task39.txt" "${result_path_q1}/task40.txt" "${result_path_q1}/task41.txt" "${result_path_q1}/task42.txt" "${target_file}"


# joinproject
result_path_q2="${ROOT_PATH}/log/result/joinproject"
# Q2-3-Hop
append "${result_path_q2}/task1.txt" "${result_path_q2}/task2.txt" "${result_path_q2}/task3.txt" "${result_path_q2}/task4.txt" "${result_path_q2}/task5.txt" "${result_path_q2}/task6.txt" "${target_file}"

# Q2-4-Hop
append "${result_path_q2}/task7.txt" "${result_path_q2}/task8.txt" "${result_path_q2}/task9.txt" "${result_path_q2}/task10.txt" "${result_path_q2}/task11.txt" "${result_path_q2}/task12.txt" "${target_file}"

# Q2-dumbbell
append "${result_path_q2}/task13.txt" "${result_path_q2}/task14.txt" "${result_path_q2}/task15.txt" "${result_path_q2}/task16.txt" "${result_path_q2}/task17.txt" "${result_path_q2}/task18.txt" "${target_file}"


# aggquery
result_path_q3="${ROOT_PATH}/log/result/aggquery"
# Q3-star_cnt
append "${result_path_q3}/task1.txt" "${result_path_q3}/task2.txt" "${result_path_q3}/task3.txt" "${result_path_q3}/task4.txt" "${result_path_q3}/task5.txt" "${result_path_q3}/task6.txt" "${target_file}"

# Q3-SNB4
append "${result_path_q3}/task7.txt" "${result_path_q3}/task8.txt" "${result_path_q3}/task9.txt" "${result_path_q3}/task10.txt" "${result_path_q3}/task11.txt" "${result_path_q3}/task12.txt" "${target_file}"


cd "${ROOT_PATH}"
mkdir -p "log/figure"
gnuplot -c "plot/figure10/plot.plt"