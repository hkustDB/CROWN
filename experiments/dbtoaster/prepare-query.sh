#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname "${SCRIPT}")
PARENT_PATH=$(dirname "${SCRIPT_PATH}")

source "${PARENT_PATH}/common.sh"

experiment_name=$1

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")

log_file="${SCRIPT_PATH}/log/prepare-query-${experiment_name}.log"

mkdir -p "${SCRIPT_PATH}/log"
chmod -f g=u "${SCRIPT_PATH}/log"
rm -f ${log_file}
touch ${log_file}
chmod -f g=u ${log_file}

dbtoaster_home=$(prop 'dbtoaster.backend.home')
cd ${dbtoaster_home}
query_file="${SCRIPT_PATH}/${experiment_name}/query.sql"
query_template_file="${SCRIPT_PATH}/${experiment_name}/query.sql.template"

output_path="${SCRIPT_PATH}/src/main/scala/experiments/dbtoaster/${experiment_name}"
mkdir -p ${output_path}
chmod -f g=u ${output_path}

output_file="${output_path}/query.scala"
input_insert_only=$(prop 'input.insert.only')

rm -f "${query_file}"
cp -f "${query_template_file}" "${query_file}"
# substitute filter condition in sql template
filter_value=$(prop 'filter.condition.value' '-1')
sed -i "s/\${filter\.condition\.value}/${filter_value}/g" "${query_file}"

echo ${input_insert_only} | grep -qi '^true$'
if [[ $? -ne 0 ]]; then
    sbt "toast -l spark --batch -O3 -d fake_del -o ${output_file} ${query_file}" >> ${log_file}
else
    sbt "toast -l spark --batch -O3 -o ${output_file} ${query_file}" >> ${log_file}
fi
assert "dbtoaster compile query failed."
chmod -f g=u ${output_file}

sed -i "1 ipackage experiments.dbtoaster.${experiment_name}" ${output_file}
sed -i '2 iimport experiments.dbtoaster.Executable' ${output_file}
sed -i '0,/object Query/{s/object Query/object Query extends Executable/}' ${output_file}

mkdir -p "${SCRIPT_PATH}/src/main/resources"
chmod -f g=u "${SCRIPT_PATH}/src/main/resources"
mkdir -p "${SCRIPT_PATH}/src/test/resources"
chmod -f g=u "${SCRIPT_PATH}/src/test/resources"

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/perf.cfg" "${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")
config="${SCRIPT_PATH}/src/main/resources/spark.config.${experiment_name}.perf"
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

CONFIG_FILES=("${SCRIPT_PATH}/${experiment_name}/func.cfg" "${SCRIPT_PATH}/${experiment_name}/common.cfg" "${SCRIPT_PATH}/experiment.cfg")
config="${SCRIPT_PATH}/src/main/resources/spark.config.${experiment_name}.func"
rm -f ${config}
echo "spark.master.url=$(prop 'spark.master.url')" >> $config
echo "spark.partitions.num=$(prop 'spark.partitions.num')" >> $config
echo "spark.driver.memory=$(prop 'spark.driver.memory')" >> $config
echo "spark.executor.memory=$(prop 'spark.executor.memory')" >> $config
echo "spark.executor.cores=$(prop 'spark.executor.cores')" >> $config
echo "spark.home.dir=$(prop 'spark.home.dir')" >> $config
echo "dist.input.path=$(prop 'hdfs.root.path')/$(prop 'hdfs.dist.dir')/" >> $config
chmod -f g=u ${config}

func_test_config="${SCRIPT_PATH}/src/test/resources/${experiment_name}.config.properties"
rm -f ${func_test_config}
echo "hdfs.data.path=$(prop 'hdfs.root.path')/$(prop 'hdfs.dist.dir')/$(prop 'dataset.name')" >> ${func_test_config}
echo "query.execute.args=-b$(prop 'batch.size.num') -d$(prop 'dataset.name') --cfg-file /spark.config.${experiment_name}.func" >> ${func_test_config}
echo "filter.condition.value=${filter_value}" >> ${func_test_config}
chmod -f g=u ${func_test_config}