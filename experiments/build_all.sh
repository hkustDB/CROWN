#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_PATH}/common.sh"

log_file="${SCRIPT_PATH}/log/build.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

# Step 1 Start
## build data-tools
echo "begin to build data-tools." >> ${log_file}
CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
log_file_temp="${SCRIPT_PATH}/data/log/prepare-tools.log"
mkdir -p "${SCRIPT_PATH}/data/log"
chmod -f g=rwx "${SCRIPT_PATH}/data/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=rw ${log_file_temp}
producer_home=$(prop 'data.tools.home')
cd ${producer_home}
rm -rf "${producer_home}/target/"
rm -rf "${producer_home}/project/target/"
rm -rf "${producer_home}/project/project/"
sbt clean >> ${log_file_temp} 2>&1
sbt compile >> ${log_file_temp} 2>&1
assert "data tools compile failed."
sbt assembly >> ${log_file_temp} 2>&1
assert "data tools assembly failed."
chmod -Rf g=u "${producer_home}/target"
chmod -Rf g=u "${producer_home}/project"
cd ${SCRIPT_PATH}
assert "build data-tools failed."
echo "finish building data-tools." >> ${log_file}
# Step 1 End

# Step 2 Start
## compile dbtoaster
echo "begin to prepare dbtoaster" >> ${log_file}
CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
log_file_temp="${SCRIPT_PATH}/dbtoaster/log/prepare-system.log"
mkdir -p "${SCRIPT_PATH}/dbtoaster/log"
chmod -f g=u "${SCRIPT_PATH}/dbtoaster/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=u ${log_file_temp}
dbtoaster_home=$(prop 'dbtoaster.backend.home')
cd ${dbtoaster_home}
rm -rf "${dbtoaster_home}/target"
rm -rf "${dbtoaster_home}/project/target"
rm -rf "${dbtoaster_home}/project/project"
sbt clean >> ${log_file_temp}
sbt compile >> ${log_file_temp}
assert "dbtoaster compile failed."
release_path="${dbtoaster_home}/ddbtoaster/release"
sbt release >> ${log_file_temp}
assert "dbtoaster release failed."
rm -rf "${SCRIPT_PATH}/dbtoaster/lib"
mkdir -p "${SCRIPT_PATH}/dbtoaster/lib"
cp ${release_path}/lib/dbt_scala/dbtoaster*.jar ${SCRIPT_PATH}/dbtoaster/lib/
chmod -Rf g=u "${release_path}"
chmod -Rf g=u "${SCRIPT_PATH}/dbtoaster/lib/"
chmod -Rf g=u "${dbtoaster_home}/target"
chmod -Rf g=u "${dbtoaster_home}/project"
cd ${SCRIPT_PATH}
assert "prepare dbtoaster failed."
echo "finish preparing dbtoaster" >> ${log_file}
# Step 2 End


function build_task {
    spec_file=$1
    current_task=$2
    CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
    system=$(prop "task${current_task}.system.name")
    experiment=$(prop "task${current_task}.experiment.name")
    data_path=''

    if [[ ${experiment} != snb* ]]; then
        data_path=${SCRIPT_PATH}/data/${experiment}
        
    else
        snb_data_path=$(prop 'snb.data.base.path')
        data_path=${snb_data_path}/${system}/${experiment}
    fi

    if [[ "${system}" == "dbtoaster" ]]; then
        if [ ${experiment} == "TwoComb" ] || [ ${experiment} == "snb4_window" ] || [ ${experiment} == "dumbbell" ]; then
            # dbtoaster build TwoComb, snb4_window, dumbbell will be compile failed, skip it.
            return 1
        fi
        echo "dbtoaster" >> ${log_file}
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        log_file_temp="${SCRIPT_PATH}/dbtoaster/log/prepare-data-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/dbtoaster/log"
        chmod -f g=u "${SCRIPT_PATH}/dbtoaster/log"
        rm -f ${log_file_temp}
        touch ${log_file_temp}
        chmod -f g=u ${log_file_temp}
        root=$(prop 'hdfs.root.path')
        dist=$(prop 'hdfs.dist.dir')
        dataset=$(prop "task${current_task}.dataset.name")
        hdfs_path=$(prop 'hdfs.cmd.path')
        ${hdfs_path} dfs -mkdir -p ${root}/${dist}/${dataset} >> ${log_file_temp} 2>&1
        assert "HDFS create dataset directory failed."
        ${hdfs_path} dfs -rm -r ${root}/${dist}/${dataset}/checkpoint >> ${log_file_temp} 2>&1
        multiplier=$(prop "task${current_task}.line.count.multiplier" '1')
        batch_size=$(prop 'batch.size.num')
        if [[ ${experiment} = snb* ]]; then
            files=$(find "${data_path}" -maxdepth 1 -type f -name 'dbtoaster.*.csv')
            for file in ${files[@]}
            do
                filename=$(basename ${file})
                ${hdfs_path} dfs -put -f "${file}" ${root}/${dist}/${dataset}/${filename} >> ${log_file_temp} 2>&1
                assert "HDFS put file failed."
            done
            cp "${data_path}/enum-points-perf.txt" "${SCRIPT_PATH}/dbtoaster/${experiment}/enum-points-perf.txt"
        else
            files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
            for file in ${files[@]}
            do
                filename=$(basename ${file})
                bash "${SCRIPT_PATH}/data/convert-data.sh" "dbtoaster" "${file}" "/tmp/${filename}.dbtoaster.tmp" "${multiplier}" "${batch_size}" "${SCRIPT_PATH}/dbtoaster/${experiment}/enum-points-perf.txt"
                ${hdfs_path} dfs -put -f /tmp/${filename}.dbtoaster.tmp ${root}/${dist}/${dataset}/${filename} >> ${log_file_temp} 2>&1
                assert "HDFS put file failed."
                rm -f /tmp/${filename}.dbtoaster.tmp
            done
        fi

        log_file_temp="${SCRIPT_PATH}/dbtoaster/log/prepare-query-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/dbtoaster/log"
        chmod -f g=u "${SCRIPT_PATH}/dbtoaster/log"
        rm -f ${log_file_temp}
        touch ${log_file_temp}
        chmod -f g=u ${log_file_temp}
        dbtoaster_home=$(prop 'dbtoaster.backend.home')
        cd ${dbtoaster_home}
        query_file="${SCRIPT_PATH}/dbtoaster/${experiment}/query.sql"
        query_template_file="${SCRIPT_PATH}/dbtoaster/${experiment}/query.sql.template"
        output_path="${SCRIPT_PATH}/dbtoaster/src/main/scala/experiments/dbtoaster/${experiment}"
        mkdir -p ${output_path}
        chmod -f g=u ${output_path}
        output_file="${output_path}/query.scala"
        input_insert_only=$(prop "task${current_task}.input.insert.only")
        rm -f "${query_file}"
        cp -f "${query_template_file}" "${query_file}"
        filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
        sed -i "s/\${filter\.condition\.value}/${filter_value}/g" "${query_file}"

        echo ${input_insert_only} | grep -qi '^true$'
        if [[ $? -ne 0 ]]; then
            sbt "toast -l spark --batch -O3 -d fake_del -o ${output_file} ${query_file}" >> ${log_file_temp}
        else
            sbt "toast -l spark --batch -O3 -o ${output_file} ${query_file}" >> ${log_file_temp}
        fi
        assert "dbtoaster compile query failed."
        chmod -f g=u ${output_file}

        sed -i "1 ipackage experiments.dbtoaster.${experiment}" ${output_file}
        sed -i '2 iimport experiments.dbtoaster.Executable' ${output_file}
        sed -i '0,/object Query/{s/object Query/object Query extends Executable/}' ${output_file}

        mkdir -p "${SCRIPT_PATH}/dbtoaster/src/main/resources"
        chmod -f g=u "${SCRIPT_PATH}/dbtoaster/src/main/resources"
        mkdir -p "${SCRIPT_PATH}/dbtoaster/src/test/resources"
        chmod -f g=u "${SCRIPT_PATH}/dbtoaster/src/test/resources"

        config="${SCRIPT_PATH}/dbtoaster/src/main/resources/spark.config.${experiment}.perf"
        rm -f ${config}
        echo "spark.master.url=$(prop 'spark.master.url')" >> $config
        echo "spark.partitions.num=$(prop 'spark.partitions.num')" >> $config
        echo "spark.driver.memory=$(prop 'spark.driver.memory')" >> $config
        echo "spark.executor.memory=$(prop 'spark.executor.memory')" >> $config
        echo "spark.executor.cores=$(prop 'spark.executor.cores')" >> $config
        echo "spark.home.dir=$(prop 'spark.home.dir')" >> $config
        echo "spark.kryoserializer.buffer.max=2047m" >> $config
        echo "dist.input.path=$(prop 'hdfs.root.path')/$(prop 'hdfs.dist.dir')/" >> $config
        chmod -f g=u ${config}

        cd ${SCRIPT_PATH}
    elif [[ "${system}" == "dbtoaster_cpp" ]]; then
        echo "dbtoaster_cpp" >> ${log_file}
        bash ${SCRIPT_PATH}/${system}/prepare-data.sh ${experiment} ${data_path}
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        log_file_temp="${SCRIPT_PATH}/dbtoaster_cpp/log/prepare-query-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/dbtoaster_cpp/log"
        chmod -f g=u "${SCRIPT_PATH}/dbtoaster_cpp/log"
        rm -f ${log_file_temp}
        touch ${log_file_temp}
        chmod -f g=u ${log_file_temp}
        dbtoaster_home=$(prop 'dbtoaster.backend.home')
        cd ${dbtoaster_home}
        query_file="${SCRIPT_PATH}/dbtoaster_cpp/${experiment}/query.sql"
        output_path="${SCRIPT_PATH}/dbtoaster_cpp/${experiment}"
        mkdir -p ${output_path}
        output_file="${output_path}/query.hpp"
        filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
        sed -i "s/\${filter\.condition\.value}/${filter_value}/g" "${query_file}"
        sbt "toast -l cpp -O3 --del -o ${output_file} ${query_file}" >> ${log_file_temp} 2>&1
        assert "dbtoaster compile query failed."
        exe_file="${output_path}/query.exe"
        g++-11 -O3 -std=c++14 -I "${dbtoaster_home}/ddbtoaster/release/lib/dbt_c++/lib/" -I "${dbtoaster_home}/ddbtoaster/release/lib/dbt_c++/driver/" "${dbtoaster_home}/ddbtoaster/release/lib/dbt_c++/driver/main.cpp" -include ${output_file} -o ${exe_file} >> ${log_file_temp} 2>&1
        chmod -Rf g=u "${SCRIPT_PATH}/dbtoaster_cpp/${experiment}"
        cd ${SCRIPT_PATH}
    elif [[ "${system}" == "flink" ]]; then
        echo "flink" >> ${log_file}
        CONFIG_FILES=("${spec_file}" "${SCRIPT_PATH}/experiment.cfg")
        target_path="${SCRIPT_PATH}/flink/src/main/resources/${experiment}"
        mkdir -p "${target_path}"
        chmod -f g=rwx "${SCRIPT_PATH}/flink/src/main/resources/${experiment}"
        rm -f "${target_path}/perf.cfg"
        touch "${target_path}/perf.cfg"
        chmod -f g=rw "${target_path}/perf.cfg"
        parallelism=$(prop 'flink.perf.parallelism')
        echo "flink.job.parallelism=${parallelism}" >> "${target_path}/perf.cfg"
        
        if [[ ${experiment} = snb* ]]; then
            files=$(find ${data_path} -maxdepth 1 -type f -name 'flink.*.csv')
            for file in ${files[@]}; do
                name=$(basename "${file}")
                echo "path.to.${name}=${file}" >> "${target_path}/perf.cfg"
            done
        else
            if [[ ${experiment} == 'TwoComb' ]]; then
                files=$(find ${data_path} -maxdepth 1 -type f -name 'flink.*.csv')
                for file in ${files[@]}; do
                    name=$(basename "${file}")
                    echo "path.to.${name}=${file}" >> "${target_path}/perf.cfg"
                done
            else
                total_lines=$(find ${data_path} -maxdepth 1 -type f -name "*.raw" | xargs wc -l | tail -n1 | awk '{print $1}')
                window_factor=$(prop 'experiment.window.factor')
                half_window_size=$(bc <<< "${total_lines}*${window_factor}/2")
                window_size=$(bc <<< "${half_window_size}*2")
                files=$(find ${data_path} -maxdepth 1 -type f -name '*.raw')
                for file in ${files[@]}; do
                    name=$(basename "${file}")
                    bash "${SCRIPT_PATH}/data/convert-data.sh" "flink" "${data_path}/${name}" "${SCRIPT_PATH}/flink/${experiment}/${name}"
                    echo "path.to.${name}=${SCRIPT_PATH}/flink/${experiment}/${name}" >> "${target_path}/perf.cfg"
                    echo "hop.window.step=${half_window_size}" >> "${target_path}/perf.cfg"
                    # convert ${hop.window.step} seconds to xx day xx hour xx minute xx second
                    step_day=$(bc <<< "${half_window_size} / 86400")
                    step_hour=$(bc <<< "(${half_window_size} - ${step_day} * 86400) / 3600")
                    step_minute=$(bc <<< "(${half_window_size} - ${step_day} * 86400 - ${step_hour} * 3600) / 60")
                    step_second=$(bc <<< "(${half_window_size} - ${step_day} * 86400 - ${step_hour} * 3600 - ${step_minute} * 60)")
                    echo "hop.window.step.day=${step_day}" >> "${target_path}/perf.cfg"
                    echo "hop.window.step.hour=${step_hour}" >> "${target_path}/perf.cfg"
                    echo "hop.window.step.minute=${step_minute}" >> "${target_path}/perf.cfg"
                    echo "hop.window.step.second=${step_second}" >> "${target_path}/perf.cfg"

                    echo "hop.window.size=${window_size}" >> "${target_path}/perf.cfg"
                    size_day=$(bc <<< "${window_size} / 86400")
                    size_hour=$(bc <<< "(${window_size} - ${size_day} * 86400) / 3600")
                    size_minute=$(bc <<< "(${window_size} - ${size_day} * 86400 - ${size_hour} * 3600) / 60")
                    size_second=$(bc <<< "(${window_size} - ${size_day} * 86400 - ${size_hour} * 3600 - ${size_minute} * 60)")
                    echo "hop.window.size.day=${size_day}" >> "${target_path}/perf.cfg"
                    echo "hop.window.size.hour=${size_hour}" >> "${target_path}/perf.cfg"
                    echo "hop.window.size.minute=${size_minute}" >> "${target_path}/perf.cfg"
                    echo "hop.window.size.second=${size_second}" >> "${target_path}/perf.cfg"
                done
            fi
        fi
        filter_value=$(prop "task${current_task}.filter.condition.value" '-1')
        echo "filter.condition.value=${filter_value}" >> "${target_path}/perf.cfg"

        mkdir -p ${SCRIPT_PATH}/flink/src/main/resources/${experiment}
        chmod -f g=rwx ${SCRIPT_PATH}/flink/src/main/resources/${experiment}
        cp -f ${SCRIPT_PATH}/flink/${experiment}/*.sql ${SCRIPT_PATH}/flink/src/main/resources/${experiment}/
        chmod -f g=rw ${SCRIPT_PATH}/flink/src/main/resources/${experiment}/*.sql
    elif [[ "${system}" == "trill" ]]; then
        echo "trill" >> ${log_file}
        key="${experiment}.perf.path"
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

        if [[ -f "${SCRIPT_PATH}/trill/${experiment}/prepare-data.sh" ]]; then
            bash "${SCRIPT_PATH}/trill/${experiment}/prepare-data.sh" "${data_path}"
        else
            if [[ ${experiment} = snb* ]]; then
                value="${data_path}"
            else
                if [[ ${experiment} == 'TwoComb' ]]; then
                    value="${data_path}"
                else
                    value="${SCRIPT_PATH}/trill/${experiment}"
                    files=$(find ${data_path} -maxdepth 1 -type f -name '*.csv')
                    for file in ${files[@]}; do
                        name=$(basename "${file}")
                        bash "${SCRIPT_PATH}/data/convert-data.sh" "trill" "${data_path}/${name}" "${SCRIPT_PATH}/trill/${experiment}/${name}"
                    done
                fi
            fi

            grep -q ${pattern} ${app_config} \
            && sed -i "s#${pattern}#<add key=\"${key}\" value=\"${value}\"/>#g" ${app_config} \
            || sed -i "/<appSettings>/a<add key=\"${key}\" value=\"${value}\"\/>" ${app_config}
        fi
    elif [[ "${system}" == "crown" ]]; then
        echo "crown" >> ${log_file}
        log_file_temp="${SCRIPT_PATH}/crown/log/prepare-data-${experiment}.log"
        mkdir -p "${SCRIPT_PATH}/crown/log"
        chmod -f g=rwx "${SCRIPT_PATH}/crown/log"
        rm -f ${log_file_temp}
        touch ${log_file_temp}
        chmod -f g=rw ${log_file_temp}
        target_path="${SCRIPT_PATH}/crown/${experiment}/perf.cfg"
        rm -f ${target_path}
        touch ${target_path}
        chmod -f g=rw ${target_path}
        if [[ ${experiment} == 'TwoComb' ]]; then
            files=$(find ${data_path} -maxdepth 1 -type f -name 'crown.*.csv')
            for file in ${files[@]}; do
                echo "path.to.data.csv=${file}" >> "${target_path}"
            done
        else
            files=$(find "${data_path}" -maxdepth 1 -type f -name '*.csv')
            for file in ${files[@]}
            do
                filename=$(basename ${file})
                echo "path.to.${filename}=${data_path}/${filename}" >> "${target_path}"
            done
        fi
    else
        echo "No need to build for system ${system}" >> ${log_file}
    fi
    assert "prepare data/query for system ${system} in experiment ${experiment} failed."
}

function build_spec {
    spec_file=$1
    echo "build_spec ${spec_file}" >> ${log_file}
    CONFIG_FILES=(${spec_file})
    task_count=$(prop 'spec.tasks.count')
    echo "task_count ${task_count}" >> ${log_file}
    current_task=1
    while [[ ${current_task} -le ${task_count} ]]
    do
        echo "build_task ${current_task}" >> ${log_file}
        build_task ${spec_file} ${current_task}
        current_task=$(($current_task+1))
    done
}


# Step 3 Start
# prepare for figure10
figure10_experiment_names=('length3_filter' 'length4_filter' 'TwoComb' 'snb1_window' 'snb2_window' 'snb3_window' 'dumbbell_full' 'length3_project' 'length4_project' 'dumbbell' 'star_cnt' 'snb4_window')
for experiment in ${figure10_experiment_names[@]}; do
    if [[ ${experiment} != snb* ]]; then
        echo "begin to produce data for experiment ${experiment}" >> ${log_file}
        if [[ ${experiment} == "TwoComb" ]]; then
            CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
            log_file_temp="${SCRIPT_PATH}/data/log/produce-data-${experiment}.log"
            mkdir -p "${SCRIPT_PATH}/data/log"
            chmod -f g=rwx "${SCRIPT_PATH}/data/log"
            rm -f ${log_file_temp}
            touch ${log_file_temp}
            chmod -f g=rw ${log_file_temp}
            graphdir=$(prop 'graph.input.path')
            graph_input_path="${graphdir}/epinions.txt"
            graph_raw_path="${SCRIPT_PATH}/data/${experiment}/data.raw"
            graph_output_path="${SCRIPT_PATH}/data/${experiment}"
            cp -f ${graph_input_path} "${graph_raw_path}"
            cd ${SCRIPT_PATH}/TwoComb
            bash "${SCRIPT_PATH}/TwoComb/convert_graph.sh" "${graph_raw_path}" "${graph_output_path}"
            chmod -Rf g=rw "${SCRIPT_PATH}/data/${experiment}/"
            cd ${SCRIPT_PATH}
        else
            CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
            log_file_temp="${SCRIPT_PATH}/data/log/produce-data-${experiment}.log"
            mkdir -p "${SCRIPT_PATH}/data/log"
            chmod -f g=rwx "${SCRIPT_PATH}/data/log"
            rm -f ${log_file_temp}
            touch ${log_file_temp}
            chmod -f g=rw ${log_file_temp}
            tools_home=$(prop 'data.tools.home')
            window_factor=$(prop 'experiment.window.factor')
            # figure10 use epinions.txt
            graphdir=$(prop 'graph.input.path')
            graph_input_path="${graphdir}/epinions.txt"
            graph_raw_path="${SCRIPT_PATH}/data/${experiment}/data.raw"
            graph_output_path="${SCRIPT_PATH}/data/${experiment}/data.csv"
            cp -f ${graph_input_path} "${graph_raw_path}"
            java -jar "${tools_home}/target/data-tools.jar" -w "${graph_raw_path}" "${graph_output_path}" "${window_factor}" >> ${log_file_temp} 2>&1
            chmod -Rf g=rw "${SCRIPT_PATH}/data/${experiment}/"
        fi
        assert "produce data for experiment ${experiment} failed."
        echo "finish producing data for experiment ${experiment}" >> ${log_file}
    fi
done

build_spec "${SCRIPT_PATH}/specs/full_join_queries.spec"
build_spec "${SCRIPT_PATH}/specs/join_project_queries.spec"
build_spec "${SCRIPT_PATH}/specs/agg_queries.spec"
# Step 3 End


# Step 4 Start
## build executable for dbtoaster
echo "begin to build executable for dbtoaster" >> ${log_file}
log_file_temp="${SCRIPT_PATH}/dbtoaster/log/build.log"
mkdir -p "${SCRIPT_PATH}/dbtoaster/log"
chmod -f g=u "${SCRIPT_PATH}/dbtoaster/log"
### also mkdir for dbtoaster_cpp
mkdir -p "${SCRIPT_PATH}/dbtoaster_cpp/log"
chmod -f g=u "${SCRIPT_PATH}/dbtoaster_cpp/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=u ${log_file_temp}
cd ${SCRIPT_PATH}/dbtoaster
rm -rf "${SCRIPT_PATH}/dbtoaster/target"
rm -rf "${SCRIPT_PATH}/dbtoaster/project/target"
rm -rf "${SCRIPT_PATH}/dbtoaster/project/project"
sbt clean >> ${log_file_temp} 2>&1
sbt compile >> ${log_file_temp} 2>&1
assert "dbtoaster executable compile failed."
sbt assembly >> ${log_file_temp} 2>&1
assert "dbtoaster executable assembly failed."
chmod -Rf g=u "${SCRIPT_PATH}/dbtoaster/target"
chmod -Rf g=u "${SCRIPT_PATH}/dbtoaster/project"
cd ${SCRIPT_PATH}
assert "build executable for dbtoaster failed."
echo "finish building executable for dbtoaster" >> ${log_file}

## build executable for flink
echo "begin to build executable for flink" >> ${log_file}
log_file_temp="${SCRIPT_PATH}/flink/log/build.log"
mkdir -p "${SCRIPT_PATH}/flink/log"
chmod -f g=rwx "${SCRIPT_PATH}/flink/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=rw ${log_file_temp}
cd ${SCRIPT_PATH}/flink
rm -rf "${SCRIPT_PATH}/flink/target/"
mvn "clean" >> ${log_file_temp} 2>&1
mvn "compile" "-DskipTests" >> ${log_file_temp} 2>&1
assert "flink executable compile failed."
mvn "package" "-DskipTests" >> ${log_file_temp} 2>&1
assert "flink executable package failed."
chmod -Rf g=u "${SCRIPT_PATH}/flink/target/"
cd ${SCRIPT_PATH}
assert "build executable for flink failed."
echo "finish building executable for flink" >> ${log_file}

## build executable for trill
echo "begin to build executable for trill" >> ${log_file}
log_file_temp="${SCRIPT_PATH}/trill/log/build.log"
mkdir -p "${SCRIPT_PATH}/trill/log"
chmod -f g=rwx "${SCRIPT_PATH}/trill/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=rw ${log_file_temp}
cd ${SCRIPT_PATH}/trill
rm -rf "${SCRIPT_PATH}/trill/bin"
rm -rf "${SCRIPT_PATH}/trill/obj"
dotnet build "${SCRIPT_PATH}/trill/experiments-trill.csproj" "/property:GenerateFullPaths=true" "/consoleloggerparameters:NoSummary" >> ${log_file_temp} 2>&1
assert "trill executable build failed."
chmod -Rf g=u "${SCRIPT_PATH}/trill/bin"
chmod -Rf g=u "${SCRIPT_PATH}/trill/obj"
chmod -Rf g=u "${SCRIPT_PATH}/trill/bin"
chmod -Rf g=u "${SCRIPT_PATH}/trill/obj"
assert "build executable for trill failed."
echo "finish building executable for trill" >> ${log_file}

## build executable for crown
echo "begin to build executable for crown" >> ${log_file}
CONFIG_FILES=("${SCRIPT_PATH}/experiment.cfg")
log_file_temp="${SCRIPT_PATH}/crown/log/build.log"
mkdir -p "${SCRIPT_PATH}/crown/log"
chmod -f g=rwx "${SCRIPT_PATH}/crown/log"
rm -f ${log_file_temp}
touch ${log_file_temp}
chmod -f g=rw ${log_file_temp}
crown_home=$(prop 'crown.code.home')
cd ${crown_home}
rm -rf "${crown_home}/target/"
mvn "clean" >> ${log_file_temp} 2>&1
mvn "compile" "-DskipTests=true" >> ${log_file_temp} 2>&1
assert "crown compile failed."
mvn "package" "-DskipTests=true" >> ${log_file_temp} 2>&1
assert "crown package failed."
chmod -Rf g=u "${crown_home}/target/"
cd ${SCRIPT_PATH}
assert "build executable for crown failed."
echo "finish building executable for crown" >> ${log_file}
# Step 4 End