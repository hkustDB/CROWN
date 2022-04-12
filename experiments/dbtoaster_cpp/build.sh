#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

flag_skip_test=$1

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"

if [[ ${flag_skip_test} -eq 0 ]]; then
    for experiment_name in ${valid_experiment_names[@]}; do
        # need to set CONFIG_FILES for each experiment
        CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

        execute_log="${SCRIPT_PATH}/log/func-test-${experiment_name}.log"
        rm -f ${execute_log}
        touch ${execute_log}
        chmod -f g=u ${execute_log}

        # func test for dbtoaster_cpp
        "${SCRIPT_PATH}/${experiment_name}/func/query.exe" -r 1 --with-detail >> ${execute_log} 2>&1
        assert "dbtoaster_cpp func test for experiment ${experiment_name} failed in execution."

        # drop the first 6 lines and the last 3 lines in execute_log
        func_test_result="${SCRIPT_PATH}/log/func-test.result"
        tail -n +6 "${execute_log}" | head -n -3 > "${func_test_result}"
        chmod -f g=u ${func_test_result}

        # pass filter_value to validate script
        filter_value=$(prop 'filter.condition.value' '-1')

        # NOTE: 'dbtoastercpp' contains no underscore because it is used as package path
        bash "${PARENT_PATH}/data/validate-result.sh" "dbtoastercpp" "${experiment_name}" "${func_test_result}" "${SCRIPT_PATH}/${experiment_name}/func/" "${filter_value}"
        assert "dbtoaster_cpp func test for experiment ${experiment_name} failed in validation."
    done
fi
