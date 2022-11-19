# SNB DATA gen
Files for generating data for SNB queries.

## Download 
1. Clone ldbc_snb_datagen_spark from https://github.com/ldbc/ldbc_snb_datagen_spark
2. Build the datagen following the README

## Add script
Add the following script `run.sh` under ldbc_snb_datagen_spark
```shell
#!/bin/bash

export PLATFORM_VERSION="2.12_spark3.2"
export DATAGEN_VERSION="0.4.0+276-7895e28c"
export LDBC_SNB_DATAGEN_JAR="/path/to/ldbc_snb_datagen_spark/target/ldbc_snb_datagen_2.12_spark3.2-0.4.0+276-7895e28c-jar-with-dependencies.jar"

export SPARK_HOME="/path/to/spark-3.2.2-bin-hadoop3.2" 
# export PYTHONPATH="/path/to/py_install"
export PATH="${SPARK_HOME}/bin:${PATH}"

SF=$1

./tools/run.py --parallelism 1 --memory 180g -- --format csv --scale-factor ${SF} --mode raw
```
`PLATFORM_VERSION`, `DATAGEN_VERSION`, and `LDBC_SNB_DATAGEN_JAR` should be configured as
```shell
PLATFORM_VERSION=$(sbt -batch -error 'print platformVersion')
DATAGEN_VERSION=$(sbt -batch -error 'print version')
LDBC_SNB_DATAGEN_JAR=$(sbt -batch -error 'print assembly / assemblyOutputPath')
```
`SPARK_HOME` is your local path to spark for running the datagen. Set `PYTHONPATH` if you the `tools` to other path in the previous step

## Run datagen
Run the datagen by `bash run.sh 3` to generate raw SNB data under scale factor 3
The scale factor can be set to `0.003`, `0.1`, `0.3`, `1`, `3`, `10`, ...

## Convert 
1. Set the paths at the head of `snb_data_convert.sh`
2. Set the `SF` to the scale factor in data generation, replacing the `.` to `_`
3. Create a database in PostgreSql with name `snb_sf${SF}`
4. Run `bash snb_data_convert.sh`
5. The converted data can be found under `${BASE_PATH}/SF_${SF}`

## WindowSize
The window size is 180 days by default, and the window step must be half of the window size. You can set window size to another value by replacing 180 in `snb_data_convert.sh`. Then you should substitute 15552000 with the corresponding seconds. 