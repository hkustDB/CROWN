#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")

valid_system_names=('dbtoaster' 'dbtoaster_cpp' 'flink' 'trill' 'crown')
valid_experiment_names=('length3_filter' 'length3_project' 'length4_filter' 'length4_project' 'star_cnt' 'snb1_window' 'snb1_arbitrary' 'snb2_window' 'snb2_arbitrary' 'snb3_window' 'snb3_arbitrary' 'snb4_window' 'snb4_arbitrary' 'dumbbell')

function err {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

function prop {
    for config_file in ${CONFIG_FILES[@]}; do
        # search the property key in config file if file exists
        if [[ -f ${config_file} ]]; then
            result=$(grep "^\s*$1=" $config_file | tail -n1 | cut -d '=' -f2)
            if [[ -n ${result} ]]; then
                break
            fi
        fi
    done

    if [[ -n ${result} ]]; then
        echo ${result}
    elif [[ $# -gt 1 ]]; then
        echo $2
    else
        err "ERROR: can not find prop $1"
        exit 1
    fi
}

function assert {
    if [[ $? -ne 0 ]]; then
        err "ERROR: ${1:-'assertion failed.'}"
        exit 1
    fi
}
