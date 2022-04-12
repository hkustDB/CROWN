#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

start=$(cat "${SCRIPT_PATH}/log/execution-time.log" | awk '/Job .* (.*) switched from state CREATED to RUNNING./{print $1; exit}')
if [[ -z ${start} ]]; then
    err "extract start time of flink job failed."
    exit 1
fi

end=$(cat "${SCRIPT_PATH}/log/execution-time.log" | awk '/Job .* (.*) switched from state RUNNING to FINISHED./{print $1; exit}')
if [[ -z ${end} ]]; then
    err "extract end time of flink job failed."
    exit 1
fi

start_seconds=$(date --date="${start}" +%s)
end_seconds=$(date --date="${end}" +%s)
total=$((end_seconds-start_seconds))

# handle the corner case where the job ends on the next day
if [[ ${total} -lt 0 ]]; then
  total=$((${total} + 86400))
fi

echo "${total}.00"
